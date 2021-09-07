//
// ParentContainerTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
//

import XCTest
import Macaroni

class ParentContainerTests: BaseTestCase {
    private class TestInjectedType {}

    private class TestParametrizedInjectedType {
        var property: String

        init(property: String) {
            self.property = property
        }
    }

    private var controlValue: Int!
    private var childContainer: Container!

    override func setUp() {
        super.setUp()

        controlValue = Int.random(in: Int.min ... Int.max)
        let parentContainer = Container()
        parentContainer.register { TestInjectedType() }
        parentContainer.register { parameter in TestParametrizedInjectedType(property: "\(parameter)") }
        childContainer = Container(parent: parentContainer)
    }

    func testSimpleRegistration() throws {
        let value: TestInjectedType? = try childContainer.resolve()
        XCTAssertNotNil(value, "Could not resolve value")
    }

    func testParametrizedRegistration() throws {
        let testPropertyValue: String = "SomePropertyValue"
        let value: TestParametrizedInjectedType? = try childContainer.resolve(parameter: testPropertyValue)
        XCTAssertTrue(value?.property == testPropertyValue)
    }
}
