//
// InjectedEagerTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

private let testStringValue: String = "Yes Service!"

private struct ToInject {
    var value: String
}

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
        container.register { () -> ToInject in .init(value: testStringValue) }
        container.register { () -> MyService in MyServiceImplementation() }
        container.register { (_) -> String in testStringValue }
        return container
    }()
}

private class MyController {
    @Injected(.resolvingOnInit(from: MyContainerHolder.container))
    var myService: MyService
}

private class MyControllerWrongInjectedType {
    @Injected(.resolvingOnInit(from: MyContainerHolder.container))
    var myService: MyServiceImplementation
}

private class MyControllerNilInjected {
    @Injected(.resolvingOnInit(from: MyContainerHolder.container))
    var myValue: Int
}

private class MyControllerParametrizedInjected {
    @Injected(.resolvingOnInit(from: MyContainerHolder.container))
    var myValue: String
}

private class MyControllerInjectedWithWrapped {
    @Injected
    var property: ToInject = try! MyContainerHolder.container.resolve()
}

class InjectedEagerTests: BaseTestCase {
    func testSimpleInjected() {
        let testObject = MyController()
        XCTAssertEqual(testObject.myService.testValue, testStringValue)
    }

    func testWrongTypeInjected() {
        waitForDeathTrap(description: "Wrong type injected") {
            _ = MyControllerWrongInjectedType()
        }
    }

    func testNilInjected() {
        waitForDeathTrap(description: "Nil injected") {
            _ = MyControllerNilInjected()
        }
    }

    func testParametrizedInjected() {
        waitForDeathTrap(description: "Parametrized injected") {
            _ = MyControllerParametrizedInjected()
        }
    }

    func testInjectedWithWrapped() {
        let testObject = MyControllerInjectedWithWrapped()
        XCTAssertEqual(testObject.property.value, testStringValue)
    }
}
