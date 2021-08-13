//
// InjectedTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
//

import XCTest
@testable import Macaroni

private let testStringValue: String = "Yes Service!"

private protocol MyService: AnyObject {
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
        let container = Container()
        container.register { (_) -> String in testStringValue }
        container.register { () -> MyService in MyServiceImplementation() }
        Container.policy = .singleton(container)
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

    func testSingleInjected() {
        let testObject = MyController()

        let myService1 = testObject.myService
        let myService2 = testObject.myService

        XCTAssertTrue(myService1 === myService2)
    }
}
