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

#if swift(>=5.5)

private let testStringValue: String = "Yes Service!"

private protocol MyService: AnyObject {
    var testValue: String { get }
}

private class MyServiceImplementation: MyService {
    var testValue: String = testStringValue
}

class InjectedAsParameterTests: BaseTestCase {
    private var container = Container()

    override func setUp() {
        container = Container()
        container.register { () -> String in testStringValue }
        Container.lookupPolicy = SingletonContainer(container)
    }

    override func tearDown() {
        super.tearDown()

        Container.lookupPolicy = nil
    }

    func testSimpleInjected() {
        func test(@Injected value: String) -> String {
            value
        }

        let result = test($value: container.resolved())
        XCTAssertTrue(result == testStringValue)
    }

    func testSimpleNonInjected() {
        func test(@Injected value: String) -> String {
            value
        }

        let result = test(value: "not-injected")
        XCTAssertTrue(result == "not-injected")
    }
}

#endif
