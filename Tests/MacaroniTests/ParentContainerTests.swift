//
// ParentContainerTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
//

import XCTest
@testable import Macaroni

class ParentContainerTests: XCTestCase {
    private class TestInjectedType {}

    private var controlValue: Int!
    private var childContainer: Container!

    override func setUp() {
        super.setUp()

        controlValue = Int.random(in: Int.min ... Int.max)
        let parentContainer = Container()
        parentContainer.register { TestInjectedType() }
        childContainer = Container(parent: parentContainer)
    }

    func testSimpleRegistration() throws {
        let value: TestInjectedType? = try childContainer.resolve()
        XCTAssertNotNil(value, "Could not resolve value")
    }
}
