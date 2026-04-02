//
// SwiftTestingContainerTests
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Testing
@testable import Macaroni
import Foundation
import Synchronization

@Suite("PerTaskContainer with Swift Testing")
struct PerTaskContainerSwiftTests {
    @Test("Each test gets its own container via withContainer")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func withContainerProvidesIsolatedContainer() async {
        let policy = PerTaskContainer(factory: {
            let container = Container()
            container.register { () -> String in "isolated-value" }
            return container
        })

        await policy.withContainer {
            let container = PerTaskContainer.container
            #expect(container != nil)
            let value: String = try! container!.resolve()
            #expect(value == "isolated-value")
        }
    }

    @Test("Container is nil outside withContainer scope")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func containerNilOutsideScope() async {
        let policy = PerTaskContainer(factory: { Container() })

        #expect(PerTaskContainer.container == nil)

        await policy.withContainer {
            #expect(PerTaskContainer.container != nil)
        }

        #expect(PerTaskContainer.container == nil)
    }

    @Test("Factory creates fresh container each time")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func factoryCreatesFreshContainer() async {
        let count = Mutex(0)
        let policy = PerTaskContainer(factory: {
            count.withLock { $0 += 1 }
            return Container(name: "swift-testing-\(count.withLock { $0 })")
        })

        await policy.withContainer {
            #expect(PerTaskContainer.container?.name == "swift-testing-1")
        }

        await policy.withContainer {
            #expect(PerTaskContainer.container?.name == "swift-testing-2")
        }

        #expect(count.withLock { $0 } == 2)
    }

    @Test("Cleanup closure is called after block")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func cleanupCalledAfterBlock() async {
        let events = Mutex<[String]>([])

        let policy = PerTaskContainer(
            factory: {
                events.withLock { $0.append("factory") }
                return Container()
            },
            cleanup: { _ in events.withLock { $0.append("cleanup") } }
        )

        await policy.withContainer {
            events.withLock { $0.append("body") }
        }

        #expect(events.withLock { $0 } == ["factory", "body", "cleanup"])
    }

    @Test("Cleanup receives the factory-created container")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func cleanupReceivesCorrectContainer() async {
        let cleanedContainer: Mutex<Container?> = Mutex(nil)
        let containerInBlock: Mutex<Container?> = Mutex(nil)

        let policy = PerTaskContainer(
            factory: { Container(name: "cleanup-target") },
            cleanup: { container in cleanedContainer.withLock { $0 = container } }
        )

        await policy.withContainer {
            containerInBlock.withLock { $0 = PerTaskContainer.container }
        }

        #expect(cleanedContainer.withLock { $0 } != nil)
        #expect(cleanedContainer.withLock { $0 } === containerInBlock.withLock { $0 })
        #expect(cleanedContainer.withLock { $0 }?.name == "cleanup-target")
    }

    @Test("Works without cleanup closure")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func worksWithoutCleanup() async {
        let policy = PerTaskContainer(factory: { Container() })

        await policy.withContainer {
            #expect(PerTaskContainer.container != nil)
        }

        #expect(PerTaskContainer.container == nil)
    }

    @Test("withContainer returns the body's value")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func withContainerReturnsValue() async {
        let policy = PerTaskContainer(factory: { Container() })

        let result = await policy.withContainer { 42 }

        #expect(result == 42)
    }

    @Test("Factory registrations are resolvable")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func factoryRegistrationsResolvable() async {
        let policy = PerTaskContainer(factory: {
            let container = Container()
            container.register { () -> Int in 123 }
            container.register { () -> String in "testing" }
            return container
        })

        await policy.withContainer {
            let container = PerTaskContainer.container!
            let intVal: Int = try! container.resolve()
            let strVal: String = try! container.resolve()
            #expect(intVal == 123)
            #expect(strVal == "testing")
        }
    }
}

@Suite("PerTaskContainer parallel isolation with Swift Testing")
struct PerTaskContainerParallelSwiftTests {
    @Test("Concurrent tests are isolated", arguments: 0..<50)
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func concurrentIsolation(index: Int) async {
        let policy = PerTaskContainer(factory: {
            let container = Container()
            container.register { () -> String in "task-\(index)" }
            return container
        })

        await policy.withContainer {
            let container = PerTaskContainer.container!
            let resolved: String = try! container.resolve()
            #expect(resolved == "task-\(index)")
        }

        #expect(PerTaskContainer.container == nil)
    }
}

@Suite("PerThreadContainer with Swift Testing")
struct PerThreadContainerSwiftTests {
    @Test("Factory creates container on first access")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func factoryCreatesOnFirstAccess() {
        let factoryCallCount = Mutex(0)
        let policy = PerThreadContainer(factory: {
            factoryCallCount.withLock { $0 += 1 }
            return Container(name: "factory-\(factoryCallCount.withLock { $0 })")
        })

        let first = policy.container(for: self, file: #fileID, function: #function, line: #line)
        let second = policy.container(for: self, file: #fileID, function: #function, line: #line)

        #expect(first === second)
        #expect(factoryCallCount.withLock { $0 } == 1)
        #expect(first?.name == "factory-1")

        policy.removeContainer()
    }

    @Test("Cleanup called on removeContainer")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func cleanupCalledOnRemove() {
        let cleanedUp = Mutex(false)
        let policy = PerThreadContainer(
            factory: { Container() },
            cleanup: { _ in cleanedUp.withLock { $0 = true } }
        )

        _ = policy.container(for: self, file: #fileID, function: #function, line: #line)
        #expect(!cleanedUp.withLock { $0 })

        policy.removeContainer()
        #expect(cleanedUp.withLock { $0 })
    }

    @Test("Cleanup not called when no container exists")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func cleanupNotCalledWhenEmpty() {
        let cleanupCalled = Mutex(false)
        let policy = PerThreadContainer(
            factory: { Container() },
            cleanup: { _ in cleanupCalled.withLock { $0 = true } }
        )

        policy.removeContainer()
        #expect(!cleanupCalled.withLock { $0 })
    }

    @Test("Cleanup receives the correct container")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func cleanupReceivesCorrectContainer() {
        let cleanedContainer: Mutex<Container?> = Mutex(nil)
        let policy = PerThreadContainer(
            factory: { Container(name: "thread-cleanup") },
            cleanup: { container in cleanedContainer.withLock { $0 = container } }
        )

        let created = policy.container(for: self, file: #fileID, function: #function, line: #line)
        policy.removeContainer()

        #expect(cleanedContainer.withLock { $0 } === created)
    }

    @Test("Factory recreates after removal")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func factoryRecreatesAfterRemoval() {
        let count = Mutex(0)
        let policy = PerThreadContainer(factory: {
            count.withLock { $0 += 1 }
            return Container(name: "recreate-\(count.withLock { $0 })")
        })

        let first = policy.container(for: self, file: #fileID, function: #function, line: #line)
        #expect(first?.name == "recreate-1")
        policy.removeContainer()

        let second = policy.container(for: self, file: #fileID, function: #function, line: #line)
        #expect(second?.name == "recreate-2")
        #expect(first !== second)
        #expect(count.withLock { $0 } == 2)

        policy.removeContainer()
    }

    @Test("setContainer overrides factory")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func setContainerOverridesFactory() {
        let policy = PerThreadContainer(factory: { Container(name: "from-factory") })

        let manual = Container(name: "manual")
        policy.setContainer(manual)

        let retrieved = policy.container(for: self, file: #fileID, function: #function, line: #line)
        #expect(retrieved === manual)
        #expect(retrieved?.name == "manual")

        policy.removeContainer()
    }

    @Test("Factory registrations are resolvable")
    @available(iOS 18.0, macOS 15.0, tvOS 13.0, watchOS 6.0, *)
    func factoryRegistrationsResolvable() {
        let policy = PerThreadContainer(factory: {
            let container = Container()
            container.register { () -> Int in 77 }
            container.register { () -> String in "thread-test" }
            return container
        })

        let container = policy.container(for: self, file: #fileID, function: #function, line: #line)!
        let intVal: Int = try! container.resolve()
        let strVal: String = try! container.resolve()
        #expect(intVal == 77)
        #expect(strVal == "thread-test")

        policy.removeContainer()
    }
}
