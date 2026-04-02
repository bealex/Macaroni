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
        let policy = PerThreadContainer()
        let iterations = 50
        let expectation = expectation(description: "All threads completed")
        expectation.expectedFulfillmentCount = iterations
        var failures: [String] = []
        let failureLock = NSLock()

        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            let container = Container(name: "thread-\(index)")
            let expected = "value-\(index)"
            container.register { () -> String in expected }
            policy.setContainer(container)

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

            // Also verify via policy lookup
            if let policyContainer = policy.container(for: self, file: #fileID, function: #function, line: #line) {
                do {
                    let resolved: String = try policyContainer.resolve()
                    if resolved != expected {
                        failureLock.lock()
                        failures.append("Thread \(index) via policy: expected '\(expected)', got '\(resolved)'")
                        failureLock.unlock()
                    }
                } catch {
                    failureLock.lock()
                    failures.append("Thread \(index) via policy: resolve threw error")
                    failureLock.unlock()
                }
            } else {
                failureLock.lock()
                failures.append("Thread \(index) via policy: container was nil")
                failureLock.unlock()
            }

            policy.removeContainer()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertTrue(failures.isEmpty, "Thread isolation failures:\n\(failures.joined(separator: "\n"))")
    }

    func testPerThreadContainerRemoval() {
        let policy = PerThreadContainer()
        let container = Container(name: "test-removal")
        container.register { () -> String in "value" }

        policy.setContainer(container)
        XCTAssertNotNil(policy.container(for: self, file: #fileID, function: #function, line: #line))

        policy.removeContainer()
        XCTAssertNil(policy.container(for: self, file: #fileID, function: #function, line: #line))
    }

    // MARK: - PerTaskContainer Tests

    func testPerTaskIsolation() async {
        let iterations = 50
        var failures: [String] = []
        let failureLock = NSLock()

        await withTaskGroup(of: String?.self) { group in
            for index in 0..<iterations {
                group.addTask {
                    let container = Container(name: "task-\(index)")
                    let expected = "task-value-\(index)"
                    container.register { () -> String in expected }

                    var failure: String? = nil
                    await PerTaskContainer.$container.withValue(container) {
                        do {
                            let resolved: String = try container.resolve()
                            if resolved != expected {
                                failure = "Task \(index): expected '\(expected)', got '\(resolved)'"
                            }
                        } catch {
                            failure = "Task \(index): resolve threw error"
                        }

                        // Verify via TaskLocal
                        if let taskContainer = PerTaskContainer.container {
                            if taskContainer.name != container.name {
                                failure = "Task \(index): TaskLocal returned wrong container '\(taskContainer.name)'"
                            }
                        } else {
                            failure = "Task \(index): TaskLocal container was nil"
                        }
                    }

                    // Verify TaskLocal is cleared after withValue scope
                    if PerTaskContainer.container != nil {
                        failure = "Task \(index): TaskLocal not cleared after withValue"
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
    }

    func testPerTaskContainerNilByDefault() {
        XCTAssertNil(PerTaskContainer.container)
    }
}
