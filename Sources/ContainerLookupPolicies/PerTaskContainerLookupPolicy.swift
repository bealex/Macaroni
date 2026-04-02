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
/// Use `withContainer` to automatically create a container via the factory,
/// scope it to the current task, and clean it up afterward:
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
///
/// You can also scope a container manually via TaskLocal:
/// ```
/// await PerTaskContainer.$container.withValue(myContainer) {
///     // ...
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class PerTaskContainer: ContainerLookupPolicy {
    @TaskLocal
    public static var container: Container?

    private let factory: () -> Container
    private let cleanup: ((Container) -> Void)?

    public init(factory: @escaping () -> Container, cleanup: ((Container) -> Void)? = nil) {
        self.factory = factory
        self.cleanup = cleanup
    }

    public func withContainer<T>(_ body: () async throws -> T) async rethrows -> T {
        let container = factory()
        let result = try await PerTaskContainer.$container.withValue(container) {
            try await body()
        }
        cleanup?(container)
        return result
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        PerTaskContainer.container
    }
}
