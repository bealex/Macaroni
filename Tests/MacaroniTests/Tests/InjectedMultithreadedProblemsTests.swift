//
// InjectedMultithreadedProblemsTests
// Macaroni
//
// Created by Alex Babaev on 18 December 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
//

import Foundation
import XCTest
import Macaroni

class InjectedMultithreadedProblemsTests: XCTestCase {
    private class InjectInto {
        @Injected
        var string: String

        func useString() -> String {
            string
        }
    }

    private class InjectIntoWeakly {
        @InjectedWeakly
        var string: String?

        func useString() -> String? {
            string
        }
    }

    func testWhenContainerDeinitedWhenInjecting() {
        let testString = "Injected String"

        var container: Container? = Container()
        Container.policy = .singleton(container!)
        container?.register { () -> String in testString }

        let injectInto = InjectInto()
        container = nil
        Container.policy = .none

        XCTAssertEqual(injectInto.useString(), testString)
    }

    func testWhenContainerDeinitedWhenInjectingWeakly() {
        let testString = "Injected String"

        var container: Container? = Container()
        Container.policy = .singleton(container!)
        container?.register { () -> String? in testString }

        let injectInto = InjectIntoWeakly()
        container = nil
        Container.policy = .none

        XCTAssertEqual(injectInto.useString(), testString)
    }
}
