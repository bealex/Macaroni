//
// ContainerSelectorTests
// Macaroni
//
// Created by Alex Babaev on 27 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

class ContainerSelectorTests: BaseTestCase {
    private class TestInjectedType {}

    class MyController1 {
        @Injected
        var string: String
    }

    class MyController2 {
        @Injected
        var string: String
    }

    class CustomContainer: ContainerLookupPolicy {
        private let container1: Container
        private let container2: Container
        private let defaultContainer: Container

        init(container1: Container, container2: Container, defaultContainer: Container) {
            self.container1 = container1
            self.container2 = container2
            self.defaultContainer = defaultContainer
        }

        func container<EnclosingType>(
            for instance: EnclosingType, file: StaticString = #fileID, function: String = #function, line: UInt = #line
        ) -> Container? {
            switch instance {
                case is MyController1: return container1
                case is MyController2: return container2
                default: return defaultContainer
            }
        }
    }

    func testDefaultScope() throws {
        let checkStringScope1 = "String for scope 1"
        let checkStringScope2 = "String for scope 2"

        let defaultContainer = Container()
        let container1 = Container()
        let container2 = Container()
        container1.register { () -> String in checkStringScope1 }
        container2.register { () -> String in checkStringScope2 }
        Container.lookupPolicy = CustomContainer(container1: container1, container2: container2, defaultContainer: defaultContainer)
        addTeardownBlock { Container.lookupPolicy = nil }

        let myController1 = MyController1()
        let myController2 = MyController2()

        XCTAssertEqual(myController1.string, checkStringScope1)
        XCTAssertEqual(myController2.string, checkStringScope2)
    }
}
