//
// ParallelContainerTests
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
@testable import Macaroni

class ParallelContainerTests: XCTestCase {
    // MARK: - PerThreadContainer Tests

    func testPerThreadIsolation() {
        let iterations = 50
        let expectation = expectation(description: "All threads completed")
        expectation.expectedFulfillmentCount = iterations
        var failures: [String] = []
        let failureLock = NSLock()
        var cleanupCount = 0

        let policy = PerThreadContainer(
            factory: {
                let container = Container()
                return container
            },
            cleanup: { _ in
                failureLock.lock()
                cleanupCount += 1
                failureLock.unlock()
            }
        )

        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            // First access triggers factory
            let expected = "value-\(index)"
            let container = policy.container(for: self, file: #fileID, function: #function, line: #line)!
            container.register { () -> String in expected }

            do {
                let resolved: String = try container.resolve()
                if resolved != expected {
                    failureLock.lock()
                    failures.append("Thread \(index): expected '\(expected)', got '\(resolved)'")
                    failureLock.unlock()
                }
            } catch {
                failureLock.lock()
                failures.append("Thread \(index): resolve threw error")
                failureLock.unlock()
            }

            // Verify the same container is returned on second access
            let sameContainer = policy.container(for: self, file: #fileID, function: #function, line: #line)
            if sameContainer !== container {
                failureLock.lock()
                failures.append("Thread \(index): factory called twice for same thread")
                failureLock.unlock()
            }

            policy.removeContainer()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertTrue(failures.isEmpty, "Thread isolation failures:\n\(failures.joined(separator: "\n"))")
        XCTAssertEqual(cleanupCount, iterations, "Cleanup should be called for each thread")
    }

    func testPerThreadContainerRemoval() {
        var cleanedUp = false
        let policy = PerThreadContainer(
            factory: {
                let container = Container(name: "test-removal")
                container.register { () -> String in "value" }
                return container
            },
            cleanup: { _ in cleanedUp = true }
        )

        // First access triggers factory
        XCTAssertNotNil(policy.container(for: self, file: #fileID, function: #function, line: #line))
        XCTAssertFalse(cleanedUp)

        // Remove triggers cleanup via deinit
        policy.removeContainer()
        XCTAssertTrue(cleanedUp)
    }

    func testPerThreadManualSetContainer() {
        let policy = PerThreadContainer(factory: { Container(name: "from-factory") })

        let manual = Container(name: "manual")
        policy.setContainer(manual)

        let retrieved = policy.container(for: self, file: #fileID, function: #function, line: #line)
        XCTAssertTrue(retrieved === manual, "setContainer should override factory")

        policy.removeContainer()
    }

    func testPerThreadFactoryCalledOncePerThread() {
        var factoryCallCount = 0
        let lock = NSLock()
        let policy = PerThreadContainer(factory: {
            lock.lock()
            factoryCallCount += 1
            lock.unlock()
            let container = Container()
            container.register { () -> String in "test" }
            return container
        })

        // Multiple accesses on the same thread should call factory only once
        let first = policy.container(for: self, file: #fileID, function: #function, line: #line)
        let second = policy.container(for: self, file: #fileID, function: #function, line: #line)
        let third = policy.container(for: self, file: #fileID, function: #function, line: #line)

        XCTAssertTrue(first === second)
        XCTAssertTrue(second === third)
        XCTAssertEqual(factoryCallCount, 1)

        policy.removeContainer()
    }

    func testPerThreadFactoryRecreatesAfterRemoval() {
        var factoryCallCount = 0
        let policy = PerThreadContainer(factory: {
            factoryCallCount += 1
            return Container(name: "factory-\(factoryCallCount)")
        })

        let first = policy.container(for: self, file: #fileID, function: #function, line: #line)
        XCTAssertEqual(first?.name, "factory-1")
        XCTAssertEqual(factoryCallCount, 1)

        policy.removeContainer()

        let second = policy.container(for: self, file: #fileID, function: #function, line: #line)
        XCTAssertEqual(second?.name, "factory-2")
        XCTAssertEqual(factoryCallCount, 2)
        XCTAssertFalse(first === second)

        policy.removeContainer()
    }

    func testPerThreadCleanupReceivesCorrectContainer() {
        var cleanedContainer: Container?
        let policy = PerThreadContainer(
            factory: { Container(name: "to-cleanup") },
            cleanup: { cleanedContainer = $0 }
        )

        let created = policy.container(for: self, file: #fileID, function: #function, line: #line)
        policy.removeContainer()

        XCTAssertTrue(cleanedContainer === created)
    }

    func testPerThreadCleanupNotCalledWhenNoContainer() {
        var cleanupCalled = false
        let policy = PerThreadContainer(
            factory: { Container() },
            cleanup: { _ in cleanupCalled = true }
        )

        // Remove without ever accessing — no container was created
        policy.removeContainer()
        XCTAssertFalse(cleanupCalled)
    }

    func testPerThreadNoCleanupClosure() {
        let policy = PerThreadContainer(factory: { Container() })

        // Should work fine without cleanup closure
        _ = policy.container(for: self, file: #fileID, function: #function, line: #line)
        policy.removeContainer()

        // Container is gone, next access triggers factory again
        XCTAssertNotNil(policy.container(for: self, file: #fileID, function: #function, line: #line))
        policy.removeContainer()
    }

    func testPerThreadFactoryRegistrationsAreUsable() {
        let policy = PerThreadContainer(factory: {
            let container = Container()
            container.register { () -> Int in 42 }
            container.register { () -> String in "hello" }
            return container
        })

        let container = policy.container(for: self, file: #fileID, function: #function, line: #line)!
        let intValue: Int = try! container.resolve()
        let stringValue: String = try! container.resolve()

        XCTAssertEqual(intValue, 42)
        XCTAssertEqual(stringValue, "hello")

        policy.removeContainer()
    }

    // MARK: - PerTaskContainer Tests

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskIsolation() async {
        let iterations = 50
        var failures: [String] = []
        let failureLock = NSLock()
        var cleanupCount = 0

        let policy = PerTaskContainer(
            factory: { Container() },
            cleanup: { _ in
                failureLock.lock()
                cleanupCount += 1
                failureLock.unlock()
            }
        )

        await withTaskGroup(of: String?.self) { group in
            for index in 0..<iterations {
                group.addTask {
                    var failure: String? = nil
                    let expected = "task-value-\(index)"

                    await policy.withContainer {
                        guard let container = PerTaskContainer.container else {
                            failure = "Task \(index): container was nil inside withContainer"
                            return
                        }
                        container.register { () -> String in expected }

                        do {
                            let resolved: String = try container.resolve()
                            if resolved != expected {
                                failure = "Task \(index): expected '\(expected)', got '\(resolved)'"
                            }
                        } catch {
                            failure = "Task \(index): resolve threw error"
                        }
                    }

                    // Verify container is cleared after withContainer scope
                    if PerTaskContainer.container != nil {
                        failure = "Task \(index): container not cleared after withContainer"
                    }

                    return failure
                }
            }

            for await failure in group {
                if let failure {
                    failureLock.lock()
                    failures.append(failure)
                    failureLock.unlock()
                }
            }
        }

        XCTAssertTrue(failures.isEmpty, "Task isolation failures:\n\(failures.joined(separator: "\n"))")
        XCTAssertEqual(cleanupCount, iterations, "Cleanup should be called for each task")
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskContainerNilByDefault() {
        XCTAssertNil(PerTaskContainer.container)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskWithContainerReturnsValue() async {
        let policy = PerTaskContainer(factory: { Container() })

        let result = await policy.withContainer {
            return 42
        }

        XCTAssertEqual(result, 42)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskCleanupReceivesCorrectContainer() async {
        var cleanedContainer: Container?
        var containerInsideBlock: Container?

        let policy = PerTaskContainer(
            factory: { Container(name: "task-cleanup-test") },
            cleanup: { cleanedContainer = $0 }
        )

        await policy.withContainer {
            containerInsideBlock = PerTaskContainer.container
        }

        XCTAssertNotNil(cleanedContainer)
        XCTAssertNotNil(containerInsideBlock)
        XCTAssertTrue(cleanedContainer === containerInsideBlock)
        XCTAssertEqual(cleanedContainer?.name, "task-cleanup-test")
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskCleanupCalledAfterBlock() async {
        var events: [String] = []

        let policy = PerTaskContainer(
            factory: {
                events.append("factory")
                return Container()
            },
            cleanup: { _ in events.append("cleanup") }
        )

        await policy.withContainer {
            events.append("body")
        }

        XCTAssertEqual(events, ["factory", "body", "cleanup"])
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskNoCleanupClosure() async {
        let policy = PerTaskContainer(factory: { Container() })

        await policy.withContainer {
            XCTAssertNotNil(PerTaskContainer.container)
        }

        XCTAssertNil(PerTaskContainer.container)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskFactoryRegistrationsAreUsable() async {
        let policy = PerTaskContainer(factory: {
            let container = Container()
            container.register { () -> Int in 99 }
            container.register { () -> String in "world" }
            return container
        })

        await policy.withContainer {
            let container = PerTaskContainer.container!
            let intValue: Int = try! container.resolve()
            let stringValue: String = try! container.resolve()

            XCTAssertEqual(intValue, 99)
            XCTAssertEqual(stringValue, "world")
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskContainerNilOutsideWithContainer() async {
        let policy = PerTaskContainer(factory: { Container() })

        XCTAssertNil(PerTaskContainer.container)

        await policy.withContainer {
            XCTAssertNotNil(PerTaskContainer.container)
        }

        XCTAssertNil(PerTaskContainer.container)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskEachWithContainerCallCreatesNew() async {
        var factoryCount = 0
        let policy = PerTaskContainer(factory: {
            factoryCount += 1
            return Container(name: "task-\(factoryCount)")
        })

        await policy.withContainer {
            XCTAssertEqual(PerTaskContainer.container?.name, "task-1")
        }

        await policy.withContainer {
            XCTAssertEqual(PerTaskContainer.container?.name, "task-2")
        }

        XCTAssertEqual(factoryCount, 2)
    }
}
