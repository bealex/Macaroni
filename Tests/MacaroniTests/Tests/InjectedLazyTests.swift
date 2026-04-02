//
// InjectedTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Synchronization
import XCTest
import Macaroni

@available(macOS 15.0, *)
class InjectedLazyTests: BaseTestCase {
    let container = Container()

    override func setUp() {
        class LazyContainer {
            private static let counter: Mutex<Int> = .init(0)
            lazy var value: String = {
                let counter = Self.counter.withLock { $0 += 1; return $0 }
                print("Created value for injection, counter: \(counter)")
                return "SomeValue \(counter)"
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
