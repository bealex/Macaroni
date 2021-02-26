import XCTest
@testable import Macaroni

class SimpleContainerTests: XCTestCase {
    private class TestInjectedType {}

    private var controlValue: Int!
    private var container: SimpleContainer!

    override func setUp() {
        super.setUp()

        container = SimpleContainer()
        controlValue = Int.random(in: Int.min ... Int.max)
        container.register { TestInjectedType() }
    }

    func testSimpleRegistration() throws {
        let value: TestInjectedType? = try container.resolve()
        XCTAssertNotNil(value, "Could not resolve value")
    }
}
