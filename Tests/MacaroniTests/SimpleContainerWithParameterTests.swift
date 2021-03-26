import XCTest
@testable import Macaroni

class SimpleContainerWithParameterTests: XCTestCase {
    private class TestInjectedType {
        var control: Int

        init(control: Int) {
            self.control = control
        }
    }

    private var container: Container!

    override func setUp() {
        super.setUp()

        container = Container()
        container.register { control -> TestInjectedType in
            guard let control = control as? Int else { fatalError("Ouch") }
            return TestInjectedType(control: control)
        }
    }

    func testRegistrationWithParameterGetWithoutParameter() {
        let value: TestInjectedType?
        do {
            value = try container.resolve()
            XCTAssertNil(value, "Value is wrongly resolved without parameter")
        } catch {
            XCTAssertNotNil(error, "Value is wrongly resolved without parameter")
        }
    }

    func testRegistrationWithParameter() throws {
        let controlValue = Int.random(in: Int.min ... Int.max)
        let value: TestInjectedType? = try container.resolve(parameter: controlValue)

        XCTAssertNotNil(value, "Could not resolve value")
        XCTAssertEqual(value?.control, controlValue, "Resolved value is wrong")
    }
}
