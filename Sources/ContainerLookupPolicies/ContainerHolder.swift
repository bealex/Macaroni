//
// ContainerHolder
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

/// Wraps a Container with an optional cleanup closure that runs on `deinit`.
/// Used by `PerThreadContainer` and `PerTaskContainer` to automatically
/// clean up when the holder is removed from thread-local or task-local storage.
class ContainerHolder: @unchecked Sendable {
    let container: Container
    private let cleanup: ((Container) -> Void)?

    init(container: Container, cleanup: ((Container) -> Void)?) {
        self.container = container
        self.cleanup = cleanup
    }

    deinit {
        cleanup?(container)
    }
}
