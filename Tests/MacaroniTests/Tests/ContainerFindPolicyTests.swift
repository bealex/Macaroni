//
// ContainerFindPolicyTests
// Macaroni
//
// Created by Alex Babaev on 7 September 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
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
        private(set) var container: Container.FindPolicy.Finder

        @Injected
        var property: String

        init(container: Container.FindPolicy.Finder) {
            self.container = container
        }
    }

    override func tearDown() {
        super.tearDown()

        Container.policy = nil
    }

    private let testString = "Injected String"

    func testNoResolvePolicyInClass() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = nil

        let instance = ToInjectClass()
        waitForDeathTrap(description: "No Resolve Policy (class)") {
            _ = instance.property
        }
    }

    func testNoResolvePolicyInStruct() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = nil

        let instance = ToInjectStruct()
        waitForDeathTrap(description: "No Resolve Policy (struct)") {
            _ = instance.property
        }
    }

    func testSingletonPolicyInClass() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = .singleton(container)

        let instance = ToInjectClass()
        XCTAssertTrue(instance.property == testString)
    }

    func testSingletonPolicyInStruct() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = .singleton(container)

        let instance = ToInjectStruct()
        waitForDeathTrap(description: "No Resolve Policy (struct)") {
            _ = instance.property
        }
    }

    func testFromEnclosedObjectPolicyFail() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = .fromEnclosingObject()

        let instance = ToInjectClass()
        waitForDeathTrap(description: "From enclosed object policy fail") {
            _ = instance.property
        }
    }

    func testFromEnclosedObjectPolicyWithContainer() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = .fromEnclosingObject()

        let instance = ToInjectClassContainerable(container: .direct(container))
        XCTAssertTrue(instance.property == testString)
    }

    func testFromEnclosedObjectPolicyWithContainerFinder() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = .fromEnclosingObject()

        let instance = ToInjectClassContainerable(container: .indirect { container })
        XCTAssertTrue(instance.property == testString)
    }

    func testCustomPolicy() {
        let container = Container()
        container.register { [self] () -> String in testString }
        Container.policy = .custom { _ in container }

        let instance = ToInjectClass()
        XCTAssertTrue(instance.property == testString)
    }
}
