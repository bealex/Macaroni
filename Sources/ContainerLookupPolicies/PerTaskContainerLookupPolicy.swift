//
// PerTaskContainerLookupPolicy
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension ContainerLookupPolicy where Self == PerTaskContainer {
    static func perTask(
        factory: @escaping () -> Container,
        cleanup: ((Container) -> Void)? = nil
    ) -> ContainerLookupPolicy {
        PerTaskContainer(factory: factory, cleanup: cleanup)
    }
}

/// Lookup policy that stores a separate Container per Swift Task.
/// Designed for Swift Testing, where each `@Test` runs in its own Task.
///
/// Available on iOS 13+, macOS 10.15+ only.
///
/// Use `withContainer` to scope a factory-created container to the current task.
/// Cleanup runs automatically when the scope exits (via the holder's `deinit`).
///
/// ```
/// Container.lookupPolicy = .perTask(
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
/// // In each test:
/// await (Container.lookupPolicy as! PerTaskContainer).withContainer {
///     // @Injected properties resolve from the factory-created container
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class PerTaskContainer: ContainerLookupPolicy {
    @TaskLocal
    static var holder: ContainerHolder?

    private let factory: () -> Container
    private let cleanup: ((Container) -> Void)?

    public init(factory: @escaping () -> Container, cleanup: ((Container) -> Void)? = nil) {
        self.factory = factory
        self.cleanup = cleanup
    }

    /// The container for the current task, if any.
    public static var container: Container? {
        holder?.container
    }

    public func withContainer<T>(_ body: () async throws -> T) async rethrows -> T {
        let container = factory()
        let holder = ContainerHolder(container: container, cleanup: cleanup)
        // When withValue scope exits, the holder is released → deinit → cleanup
        return try await PerTaskContainer.$holder.withValue(holder) {
            try await body()
        }
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        PerTaskContainer.container
    }
}
