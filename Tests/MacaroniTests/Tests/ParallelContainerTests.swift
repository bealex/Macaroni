//
// ParallelContainerTests
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

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
            // Register a unique value per thread
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

        // Remove triggers cleanup
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

    // MARK: - PerTaskContainer Tests

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testPerTaskIsolation() async {
        let iterations = 50
        var failures: [String] = []
        let failureLock = NSLock()
        var cleanupCount = 0

        let policy = PerTaskContainer(
            factory: {
                Container()
            },
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

                    // Verify TaskLocal is cleared after withContainer scope
                    if PerTaskContainer.container != nil {
                        failure = "Task \(index): TaskLocal not cleared after withContainer"
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
}
