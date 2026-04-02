//
// SwiftTestingContainerTests
// Macaroni
//
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Testing
import Macaroni
import Foundation

@Suite("PerTaskContainer with Swift Testing")
struct PerTaskContainerSwiftTests {

    @Test("Each test gets its own container via withContainer")
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
    func containerNilOutsideScope() async {
        let policy = PerTaskContainer(factory: { Container() })

        #expect(PerTaskContainer.container == nil)

        await policy.withContainer {
            #expect(PerTaskContainer.container != nil)
        }

        #expect(PerTaskContainer.container == nil)
    }

    @Test("Factory creates fresh container each time")
    func factoryCreatesFreshContainer() async {
        var count = 0
        let policy = PerTaskContainer(factory: {
            count += 1
            return Container(name: "swift-testing-\(count)")
        })

        await policy.withContainer {
            #expect(PerTaskContainer.container?.name == "swift-testing-1")
        }

        await policy.withContainer {
            #expect(PerTaskContainer.container?.name == "swift-testing-2")
        }

        #expect(count == 2)
    }

    @Test("Cleanup closure is called after block")
    func cleanupCalledAfterBlock() async {
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

        #expect(events == ["factory", "body", "cleanup"])
    }

    @Test("Cleanup receives the factory-created container")
    func cleanupReceivesCorrectContainer() async {
        var cleanedContainer: Container?
        var containerInBlock: Container?

        let policy = PerTaskContainer(
            factory: { Container(name: "cleanup-target") },
            cleanup: { cleanedContainer = $0 }
        )

        await policy.withContainer {
            containerInBlock = PerTaskContainer.container
        }

        #expect(cleanedContainer != nil)
        #expect(cleanedContainer === containerInBlock)
        #expect(cleanedContainer?.name == "cleanup-target")
    }

    @Test("Works without cleanup closure")
    func worksWithoutCleanup() async {
        let policy = PerTaskContainer(factory: { Container() })

        await policy.withContainer {
            #expect(PerTaskContainer.container != nil)
        }

        #expect(PerTaskContainer.container == nil)
    }

    @Test("withContainer returns the body's value")
    func withContainerReturnsValue() async {
        let policy = PerTaskContainer(factory: { Container() })

        let result = await policy.withContainer { 42 }

        #expect(result == 42)
    }

    @Test("Factory registrations are resolvable")
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
    func factoryCreatesOnFirstAccess() {
        var factoryCallCount = 0
        let policy = PerThreadContainer(factory: {
            factoryCallCount += 1
            return Container(name: "factory-\(factoryCallCount)")
        })

        let first = policy.container(for: self, file: #fileID, function: #function, line: #line)
        let second = policy.container(for: self, file: #fileID, function: #function, line: #line)

        #expect(first === second)
        #expect(factoryCallCount == 1)
        #expect(first?.name == "factory-1")

        policy.removeContainer()
    }

    @Test("Cleanup called on removeContainer")
    func cleanupCalledOnRemove() {
        var cleanedUp = false
        let policy = PerThreadContainer(
            factory: { Container() },
            cleanup: { _ in cleanedUp = true }
        )

        _ = policy.container(for: self, file: #fileID, function: #function, line: #line)
        #expect(!cleanedUp)

        policy.removeContainer()
        #expect(cleanedUp)
    }

    @Test("Cleanup not called when no container exists")
    func cleanupNotCalledWhenEmpty() {
        var cleanupCalled = false
        let policy = PerThreadContainer(
            factory: { Container() },
            cleanup: { _ in cleanupCalled = true }
        )

        policy.removeContainer()
        #expect(!cleanupCalled)
    }

    @Test("Cleanup receives the correct container")
    func cleanupReceivesCorrectContainer() {
        var cleanedContainer: Container?
        let policy = PerThreadContainer(
            factory: { Container(name: "thread-cleanup") },
            cleanup: { cleanedContainer = $0 }
        )

        let created = policy.container(for: self, file: #fileID, function: #function, line: #line)
        policy.removeContainer()

        #expect(cleanedContainer === created)
    }

    @Test("Factory recreates after removal")
    func factoryRecreatesAfterRemoval() {
        var count = 0
        let policy = PerThreadContainer(factory: {
            count += 1
            return Container(name: "recreate-\(count)")
        })

        let first = policy.container(for: self, file: #fileID, function: #function, line: #line)
        #expect(first?.name == "recreate-1")
        policy.removeContainer()

        let second = policy.container(for: self, file: #fileID, function: #function, line: #line)
        #expect(second?.name == "recreate-2")
        #expect(first !== second)
        #expect(count == 2)

        policy.removeContainer()
    }

    @Test("setContainer overrides factory")
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
