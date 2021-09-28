//
// InjectedTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

private let testStringValue: String = "Yes Service!"
private let testIntValue: Int = 239

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

private class MyControllerWrongInjection {
    @Injected
    var myProperty: Int
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

class InjectedTests: BaseTestCase {
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

    func testInjectionFail() {
        let testObject = MyControllerWrongInjection()

        waitForDeathTrap(description: "No value to inject") {
            _ = testObject.myProperty
        }
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
