import XCTest
@testable import Macaroni

private let testStringValue: String = "Yes Service!"

private protocol MyService {
    var testValue: String { get }
}

private class MyServiceImplementation: MyService {
    var testValue: String = testStringValue
}

private enum MyContainerHolder {
    static var container: Container = {
        let container = Container()
        container.register { () -> Int? in nil }
        container.register { () -> MyService in MyServiceImplementation() }
        container.register { (_) -> String in testStringValue }
        return container
    }()
}

private class MyController {
    @InjectedFrom(container: MyContainerHolder.container)
    var myService: MyService
}

private class MyControllerWrongInjectedType {
    @InjectedFrom(container: MyContainerHolder.container)
    var myService: MyServiceImplementation
}

private class MyControllerNilInjected {
    @InjectedFrom(container: MyContainerHolder.container)
    var myValue: Int
}

private class MyControllerParametrizedInjected {
    @InjectedFrom(container: MyContainerHolder.container)
    var myValue: String
}

class TestMacaroniLogger: XCTestCase, MacaroniLogger {
    var expectationHandler: (_ message: String) -> Void = { _ in }

    func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: Int) {
    }

    func die() -> Never {
        expectationHandler("Macaroni is dead")
        repeat { RunLoop.current.run() } while (true) // For never to work
    }
}

class InjectedFromTests: XCTestCase {
    func expectFatalError(description: String, testCase: @escaping () -> Void) {
        let expectation = self.expectation(description: description)

        let logger = TestMacaroniLogger()
        logger.expectationHandler = { _ in expectation.fulfill() }
        Macaroni.logger = logger

        DispatchQueue.global(qos: .userInitiated).async(execute: testCase)
        waitForExpectations(timeout: 1) { _ in
            Macaroni.logger = SimpleMacaroniLogger()
        }
    }

    func testSimpleInjected() {
        let testObject = MyController()
        XCTAssertEqual(testObject.myService.testValue, testStringValue)
    }

    func testWrongTypeInjected() {
        expectFatalError(description: "Wrong type injected") {
            _ = MyControllerWrongInjectedType()
        }
    }

    func testNilInjected() {
        expectFatalError(description: "Nil injected") {
            _ = MyControllerNilInjected()
        }
    }

    func testParametrizedInjected() {
        expectFatalError(description: "Parametrized injected") {
            _ = MyControllerParametrizedInjected()
        }
    }
}
