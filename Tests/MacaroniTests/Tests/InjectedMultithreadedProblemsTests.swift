//
// InjectedMultithreadedProblemsTests
// Macaroni
//
// Created by Alex Babaev on 18 December 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
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
        Container.lookupPolicy = .singleton(container!)
        container?.register { () -> String in testString }

        let injectInto = InjectInto()
        container = nil
        Container.lookupPolicy = nil

        XCTAssertEqual(injectInto.useString(), testString)
    }

    func testWhenContainerDeinitedWhenInjectingWeakly() {
        let testString = "Injected String"

        var container: Container? = Container()
        Container.lookupPolicy = .singleton(container!)
        container?.register { () -> String? in testString }

        let injectInto = InjectIntoWeakly()
        container = nil
        Container.lookupPolicy = nil

        XCTAssertEqual(injectInto.useString(), testString)
    }
}
