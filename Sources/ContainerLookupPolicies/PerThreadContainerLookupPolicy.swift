//
// PerThreadContainerLookupPolicy
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

public extension ContainerLookupPolicy where Self == PerThreadContainer {
    static func perThread(
        factory: @escaping @Sendable () -> Container,
        cleanup: (@Sendable (Container) -> Void)? = nil
    ) -> ContainerLookupPolicy {
        PerThreadContainer(factory: factory, cleanup: cleanup)
    }
}

/// Lookup policy that stores a separate Container per thread.
/// Designed for XCTest parallel testing, where each test class runs on its own thread.
///
/// On first access from a thread, the factory closure creates a new Container.
/// Cleanup runs automatically when `removeContainer()` is called (via the holder's `deinit`).
///
/// Usage:
/// ```
/// Container.lookupPolicy = .perThread(
///     factory: {
///         let container = Container()
///         container.register { MyService() as MyServiceProtocol }
///         return container
///     },
///     cleanup: { container in
///         container.cleanup()
///     }
/// )
///
/// // In tearDown:
/// (Container.lookupPolicy as! PerThreadContainer).removeContainer()
/// ```
public final class PerThreadContainer: ContainerLookupPolicy {
    private static let threadDictionaryKey = "Macaroni.PerThreadContainer.holder"

    private let factory: @Sendable () -> Container
    private let cleanup: (@Sendable (Container) -> Void)?

    public init(factory: @escaping @Sendable () -> Container, cleanup: (@Sendable (Container) -> Void)? = nil) {
        self.factory = factory
        self.cleanup = cleanup
    }

    public func setContainer(_ container: Container) {
        let holder = ContainerHolder(container: container, cleanup: cleanup)
        Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] = holder
    }

    public func removeContainer() {
        // Removing the holder from the dictionary releases it, triggering deinit → cleanup
        Thread.current.threadDictionary.removeObject(forKey: PerThreadContainer.threadDictionaryKey)
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        if let holder = Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] as? ContainerHolder {
            return holder.container
        }
        let container = factory()
        let holder = ContainerHolder(container: container, cleanup: cleanup)
        Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] = holder
        return container
    }
}
