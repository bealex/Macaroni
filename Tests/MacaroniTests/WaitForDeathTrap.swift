//
// WaitForDeathTrap
// Macaroni
//
// Created by Alex Babaev on 7 September 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

import XCTest
import Macaroni

class BaseTestCase: XCTestCase {
    class TestMacaroniLogger: MacaroniLogger {
        let deathHandler: () -> Void

        init(deathHandler: @escaping () -> Void) {
            self.deathHandler = deathHandler
        }

        func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: UInt) {
        }

        func die() -> Never {
            deathHandler()
            while true { Thread.sleep(forTimeInterval: 1000) /* hang here */ }
        }
    }

    func waitForDeathTrap(description: String, testCase: @escaping () -> Void) {
        let expectation = self.expectation(description: description)
        Macaroni.logger = TestMacaroniLogger {
            Macaroni.logger = SimpleMacaroniLogger()
            expectation.fulfill()
        }

        DispatchQueue.global(qos: .userInitiated).async(execute: testCase)
        waitForExpectations(timeout: 1) { _ in
            // wait
        }
    }
}
