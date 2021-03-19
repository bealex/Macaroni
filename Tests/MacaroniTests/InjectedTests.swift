import XCTest
@testable import Macaroni

private let testStringValue: String = "Yes Service!"

private protocol MyService {
    var testValue: String { get }
}

private class MyServiceImplementation: MyService {
    var testValue: String = testStringValue
}

private class MyController {
    @Injected
    var myService: MyService
    @Injected
    var myStringInitializingWithParameter: String
}

private class MyControllerWithOptionals {
    @Injected
    var myOptionalService: MyService?
    @Injected
    var myOptionalString: String?
}

private class MyControllerWithForcedOptionals {
    @Injected
    var myForceUnwrappedOptionalService: MyService!
}

class InjectedTests: XCTestCase {
    override func setUp() {
        let container = ContainerSelector.defaultContainer
        container.register { (_) -> String in testStringValue }
        container.register { () -> MyService in MyServiceImplementation() }
    }

    func testSimpleInjected() {
        let testObject = MyController()

        XCTAssertEqual(testObject.myService.testValue, testStringValue)
        XCTAssertEqual(testObject.myStringInitializingWithParameter, testStringValue)
    }

    func testOptionalInjected() {
        let testObject = MyControllerWithOptionals()

        XCTAssertEqual(testObject.myOptionalService?.testValue, testStringValue)
        XCTAssertEqual(testObject.myOptionalString, testStringValue)
    }

    func testForcedOptionalInjected() {
        let testObject = MyControllerWithForcedOptionals()

        XCTAssertEqual(testObject.myForceUnwrappedOptionalService.testValue, testStringValue)
    }
}
