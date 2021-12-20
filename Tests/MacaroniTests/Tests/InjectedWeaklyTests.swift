//
// InjectedWeaklyTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

private let testStringValue: String = "Yes Service!"

private protocol MyService: AnyObject {}
private class MyServiceImplementation: MyService {}

private class MyController {
    @InjectedWeakly
    var myService: MyService?
}

class InjectedWeaklyTests: BaseTestCase {
    static let container = Container()

    override class func setUp() {
        Container.lookupPolicy = .singleton(container)
    }

    override class func tearDown() {
        super.tearDown()
        Container.lookupPolicy = nil
    }

    override func setUp() {
        Self.container.cleanup()
    }

    func testWeaklyInjected() {
        let register: () -> MyService = {
            let service: MyService = MyServiceImplementation()
            Self.container.register { [weak service] in service }
            return service
        }

        var service: MyService? = register()
        print("(just need to silence warning) \(String(describing: service))")
        let testObject = MyController()
        XCTAssertNotNil(testObject.myService)
        service = nil
        XCTAssertNil(testObject.myService)
    }

    func testWeaklyNilInjected() {
        Self.container.register { () -> MyService? in nil }

        let testObject = MyController()
        XCTAssertNil(testObject.myService)
    }

    func testSingleInjected() {
        Self.container.register { () -> MyService? in MyServiceImplementation() }
        let testObject = MyController()

        let myService1 = testObject.myService
        let myService2 = testObject.myService

        XCTAssertTrue(myService1 === myService2)
    }
}
