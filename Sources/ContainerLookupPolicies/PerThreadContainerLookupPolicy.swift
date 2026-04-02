//
// PerThreadContainerLookupPolicy
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

public extension ContainerLookupPolicy where Self == PerThreadContainer {
    static func perThread(
        factory: @escaping () -> Container,
        cleanup: ((Container) -> Void)? = nil
    ) -> ContainerLookupPolicy {
        PerThreadContainer(factory: factory, cleanup: cleanup)
    }
}

/// Lookup policy that stores a separate Container per thread.
/// Designed for XCTest parallel testing, where each test class runs on its own thread.
///
/// On first access from a thread, the factory closure creates a new Container for that thread.
/// When `removeContainer()` is called, the optional cleanup closure is invoked before removal.
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
public class PerThreadContainer: ContainerLookupPolicy {
    private static let threadDictionaryKey = "Macaroni.PerThreadContainer.container"

    private let factory: () -> Container
    private let cleanup: ((Container) -> Void)?

    public init(factory: @escaping () -> Container, cleanup: ((Container) -> Void)? = nil) {
        self.factory = factory
        self.cleanup = cleanup
    }

    public func setContainer(_ container: Container) {
        Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] = container
    }

    public func removeContainer() {
        if let container = Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] as? Container {
            cleanup?(container)
        }
        Thread.current.threadDictionary.removeObject(forKey: PerThreadContainer.threadDictionaryKey)
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        if let existing = Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] as? Container {
            return existing
        }
        let container = factory()
        Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] = container
        return container
    }
}
