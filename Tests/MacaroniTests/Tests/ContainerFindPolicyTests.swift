//
// ContainerFindPolicyTests
// Macaroni
//
// Created by Alex Babaev on 7 September 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

class ContainerFindPolicyTests: BaseTestCase {
    class ToInjectClass {
        @Injected
        var property: String
    }

    struct ToInjectStruct {
        @Injected
        var property: String
    }

    class ToInjectClassContainerable: Containerable {
        private(set) var container: Container!

        @Injected
        var property: String

        init(container: Container) {
            self.container = container
        }
    }

    override func tearDown() {
        super.tearDown()

        Container.lookupPolicy = nil
    }

    private let testString = "Injected String"

    func testNoResolvePolicyInClass() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.lookupPolicy = nil

        waitForDeathTrap(description: "No Resolve Policy (class)") {
            let instance = ToInjectClass()
            _ = instance.property
        }
    }

    func testNoResolvePolicyInStruct() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.lookupPolicy = nil

        waitForDeathTrap(description: "No Resolve Policy (struct)") {
            let instance = ToInjectStruct()
            _ = instance.property
        }
    }

    func testSingletonPolicyInClass() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.lookupPolicy = SingletonContainer(container)

        let instance = ToInjectClass()
        XCTAssertTrue(instance.property == testString)
    }

    func testSingletonPolicyInStruct() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.lookupPolicy = SingletonContainer(container)

        let instance = ToInjectStruct()
        waitForDeathTrap(description: "No Resolve Policy (struct)") {
            _ = instance.property
        }
    }

    func testFromEnclosedObjectPolicyFail() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.lookupPolicy = EnclosingTypeContainer()

        let instance = ToInjectClass()
        waitForDeathTrap(description: "From enclosed object policy fail") {
            _ = instance.property
        }
    }

    func testFromEnclosedObjectPolicyWithContainer() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.lookupPolicy = EnclosingTypeContainer()

        let instance = ToInjectClassContainerable(container: container)
        XCTAssertTrue(instance.property == testString)
    }
}
