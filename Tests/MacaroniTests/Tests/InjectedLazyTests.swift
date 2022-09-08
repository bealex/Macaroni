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

class InjectedLazyTests: BaseTestCase {
    let container = Container()

    override func setUp() {
        class LazyContainer {
            private static var counter: Int = 0
            lazy var value: String = {
                Self.counter += 1
                print("Created value for injection, counter: \(Self.counter)")
                return "SomeValue \(Self.counter)"
            }()
            init() {}
        }

        container.cleanup()
        let lazyContainer = LazyContainer()
        container.register { () -> String in lazyContainer.value }
        Container.lookupPolicy = .singleton(container)
        addTeardownBlock { Container.lookupPolicy = nil }
        print("Created container")
    }

    func testLazyInjection() {
        let value1: String = try! container.resolve()
        print("First resolve: \(value1)")
        let value2: String = try! container.resolve()
        print("Second resolve: \(value2)")

        XCTAssertEqual(value1, value2)
        XCTAssertEqual(value1, "SomeValue 1")
    }
}
