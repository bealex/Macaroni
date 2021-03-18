import XCTest
@testable import Macaroni

class ParentContainerTests: XCTestCase {
    private class TestInjectedType {}

    private var controlValue: Int!
    private var container: SimpleContainer!
    private var childContainer: SimpleContainer!

    override func setUp() {
        super.setUp()

        container = SimpleContainer()
        controlValue = Int.random(in: Int.min ... Int.max)
        container.register { TestInjectedType() }

        childContainer = SimpleContainer(parentContainer: container)
    }

    func testSimpleRegistration() throws {
        let value: TestInjectedType? = try childContainer.resolve()
        XCTAssertNotNil(value, "Could not resolve value")
    }
}
