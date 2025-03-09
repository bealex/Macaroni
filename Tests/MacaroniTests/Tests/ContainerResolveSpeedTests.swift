//
// ContainerResolveSpeedTest
// Macaroni
//
// Created by Alex Babaev on 27 November 2022.
// Copyright © 2022 Alex Babaev. All rights reserved.
//

import Macaroni
import XCTest

class ContainerResolveSpeedTests: XCTestCase {
    private var container: Container = .init()

    override func setUp() {
        super.setUp()

        container.register { () -> String in "Some String" }
        container.register { () -> Int in 239 }
        container.register { () -> Double in 239.239 }
    }

    override func tearDown() {
        super.tearDown()

        container.cleanup()
    }

    func testResolvingSpeed() throws {
        if #available(iOS 16, macOS 13, *) {
            let clock = ContinuousClock()
            let elapsed = clock.measure {
                for _ in 0 ... 100000 {
                    let _: String? = try? container.resolve()
                    let _: Int? = try? container.resolve()
                    let _: Double? = try? container.resolve()
                }
            }
            XCTAssertTrue(elapsed < .seconds(1), "Resolving is to slow for some reason (limit is 0.5 seconds for 300 000 resolves")
        } else {
            measure {
                for _ in 0 ... 10000 {
                    let _: String? = try? container.resolve()
                    let _: Int? = try? container.resolve()
                    let _: Double? = try? container.resolve()
                }
            }
        }
    }

    func testResolvingSpeedLocked() throws {
        container.lock()

        if #available(iOS 16, macOS 13, *) {
            let clock = ContinuousClock()
            let elapsed = clock.measure {
                for _ in 0 ... 100000 {
                    let _: String? = try? container.resolve()
                    let _: Int? = try? container.resolve()
                    let _: Double? = try? container.resolve()
                }
            }
            XCTAssertTrue(elapsed < .seconds(0.5), "Resolving is to slow for some reason (limit is 0.5 seconds for 300 000 resolves")
        } else {
            measure {
                for _ in 0 ... 10000 {
                    let _: String? = try? container.resolve()
                    let _: Int? = try? container.resolve()
                    let _: Double? = try? container.resolve()
                }
            }
        }
    }
}
