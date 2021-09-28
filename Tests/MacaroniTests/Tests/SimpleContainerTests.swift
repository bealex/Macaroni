//
// SimpleContainerTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

class SimpleContainerTests: BaseTestCase {
    private class TestInjectedType {}

    private var container: Container!

    override func setUp() {
        super.setUp()

        container = Container()
        container.register { TestInjectedType() }
    }

    func testSimpleRegistration() throws {
        let value: TestInjectedType? = try container.resolve()
        XCTAssertNotNil(value, "Could not resolve value")
    }
}
