//
// PerTaskContainerLookupPolicy
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension ContainerLookupPolicy where Self == PerTaskContainer {
    static var perTask: ContainerLookupPolicy {
        PerTaskContainer()
    }
}

/// Lookup policy that stores a separate Container per Swift Task.
/// Designed for Swift Testing, where each `@Test` runs in its own Task.
///
/// Available on iOS 13+, macOS 10.15+ only.
///
/// Usage:
/// ```
/// // Set once globally:
/// Container.lookupPolicy = .perTask
///
/// // Each test scopes its container via TaskLocal:
/// await PerTaskContainer.$container.withValue(myContainer) {
///     // @Injected properties resolve from myContainer here
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class PerTaskContainer: ContainerLookupPolicy {
    @TaskLocal
    public static var container: Container?

    public init() {}

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        PerTaskContainer.container
    }
}
