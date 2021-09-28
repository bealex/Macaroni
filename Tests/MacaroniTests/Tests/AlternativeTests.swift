//
// AlternativeTests
// Macaroni
//
// Created by Alex Babaev on 13 August 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import XCTest
import Macaroni

extension RegistrationAlternative {
    static let one: RegistrationAlternative = "one"
    static let two: RegistrationAlternative = .init("two")
}

class AlternativeTests: BaseTestCase {
    private var container: Container!

    func testSimpleAlternatives() throws {
        let objectDefault = TestInjectedClassDefault(property: nil)
        let objectOne = TestInjectedClassOne(property: nil)
        let objectTwo = TestInjectedClassTwo(property: nil)

        container = Container()
        container.register { () -> TestInjectedProtocol in objectDefault }
        container.register(alternative: .one) { () -> TestInjectedProtocol in objectOne }
        container.register(alternative: .two) { () -> TestInjectedProtocol in objectTwo }

        let valueDefault: TestInjectedProtocol? = try container.resolve()
        let valueOne: TestInjectedProtocol? = try container.resolve(alternative: .one)
        let valueTwo: TestInjectedProtocol? = try container.resolve(alternative: .two)

        XCTAssertTrue(objectDefault === valueDefault)
        XCTAssertTrue(objectOne === valueOne)
        XCTAssertTrue(objectTwo === valueTwo)
    }

    func testAlternativesInjection() throws {
        class Test {
            @Injected
            var valueDefault: TestInjectedProtocol
            @Injected(alternative: .one)
            var valueOne: TestInjectedProtocol
        }

        let objectDefault = TestInjectedClassDefault(property: nil)
        let objectOne = TestInjectedClassOne(property: nil)

        container = Container()
        Container.policy = .singleton(container)
        container.register { () -> TestInjectedProtocol in objectDefault }
        container.register(alternative: .one) { () -> TestInjectedProtocol in objectOne }

        let value = Test()

        XCTAssertTrue(objectDefault === value.valueDefault)
        XCTAssertTrue(objectOne === value.valueOne)
    }

    func testOnlyAlternative() throws {
        let objectOne = TestInjectedClassOne(property: nil)

        container = Container()
        container.register(alternative: .one) { () -> TestInjectedProtocol in objectOne }

        let valueDefault: TestInjectedProtocol?
        let valueOne: TestInjectedProtocol? = try container.resolve(alternative: .one)
        let valueTwo: TestInjectedProtocol?
        do {
            valueDefault = try container.resolve()
        } catch ContainerError.noResolver {
            valueDefault = nil
        }
        do {
            valueTwo = try container.resolve(alternative: .two)
        } catch ContainerError.noResolver {
            valueTwo = nil
        }

        XCTAssertTrue(valueDefault == nil)
        XCTAssertTrue(objectOne === valueOne)
        XCTAssertTrue(valueTwo == nil)
    }

    func testAlternativeWithParameter() throws {
        container = Container()
        container.register(alternative: .one) {
            parameter -> TestInjectedProtocol in TestInjectedClassOne(property: "\(parameter)")
        }

        let valueOne: TestInjectedProtocol?
        do {
            valueOne = try container.resolve(alternative: .one)
        } catch ContainerError.noResolver {
            valueOne = nil
        }
        let valueOneWithParameter: TestInjectedProtocol? = try container.resolve(parameter: "Parameter", alternative: .one)

        XCTAssertTrue(valueOne == nil)
        XCTAssertTrue(valueOneWithParameter != nil)
        XCTAssertTrue(valueOneWithParameter?.property == "Parameter")
    }
}

private protocol TestInjectedProtocol: AnyObject {
    var property: String? { get set }
}

private class TestInjectedClassDefault: TestInjectedProtocol {
    var property: String?

    init(property: String?) {
        self.property = property
    }
}

private class TestInjectedClassOne: TestInjectedProtocol {
    var property: String?

    init(property: String?) {
        self.property = property
    }
}

private class TestInjectedClassTwo: TestInjectedProtocol {
    var property: String?

    init(property: String?) {
        self.property = property
    }
}
