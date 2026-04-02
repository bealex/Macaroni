//
// PerThreadContainerLookupPolicy
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

public extension ContainerLookupPolicy where Self == PerThreadContainer {
    static var perThread: ContainerLookupPolicy {
        PerThreadContainer()
    }
}

/// Lookup policy that stores a separate Container per thread.
/// Designed for XCTest parallel testing, where each test class runs on its own thread.
///
/// Usage:
/// ```
/// // Set once globally (e.g., in a shared test base class setUp):
/// Container.lookupPolicy = .perThread
///
/// // Each test sets its container for its thread:
/// (Container.lookupPolicy as! PerThreadContainer).setContainer(container)
/// ```
public class PerThreadContainer: ContainerLookupPolicy {
    private static let threadDictionaryKey = "Macaroni.PerThreadContainer.container"

    public init() {}

    public func setContainer(_ container: Container) {
        Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] = container
    }

    public func removeContainer() {
        Thread.current.threadDictionary.removeObject(forKey: PerThreadContainer.threadDictionaryKey)
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        Thread.current.threadDictionary[PerThreadContainer.threadDictionaryKey] as? Container
    }
}
