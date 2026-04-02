//
// PerTaskContainerLookupPolicy
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

public extension ContainerLookupPolicy where Self == PerTaskContainer {
    static var perTask: ContainerLookupPolicy {
        PerTaskContainer()
    }
}

/// Lookup policy that stores a separate Container per Swift Task.
/// Designed for Swift Testing, where each `@Test` runs in its own Task.
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
