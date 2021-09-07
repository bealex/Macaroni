//
// SimpleContainerWithParameterTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

import XCTest
import Macaroni

class SimpleContainerWithParameterTests: BaseTestCase {
    private class TestInjectedType {
        var control: Int

        init(control: Int) {
            self.control = control
        }
    }

    private var container: Container!

    override func setUp() {
        super.setUp()

        container = Container()
        container.register { control -> TestInjectedType in
            guard let control = control as? Int else { fatalError("Ouch") }
            return TestInjectedType(control: control)
        }
    }

    func testRegistrationWithParameterGetWithoutParameter() {
        let value: TestInjectedType?
        do {
            value = try container.resolve()
            XCTAssertNil(value, "Value is wrongly resolved without parameter")
        } catch {
            XCTAssertNotNil(error, "Value is wrongly resolved without parameter")
        }
    }

    func testRegistrationWithParameter() throws {
        let controlValue = Int.random(in: Int.min ... Int.max)
        let value: TestInjectedType? = try container.resolve(parameter: controlValue)

        XCTAssertNotNil(value, "Could not resolve value")
        XCTAssertEqual(value?.control, controlValue, "Resolved value is wrong")
    }
}
