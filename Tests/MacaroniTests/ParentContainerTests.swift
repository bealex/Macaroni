import XCTest
@testable import Macaroni

class ParentContainerTests: XCTestCase {
    private class TestInjectedType {}

    private var controlValue: Int!
    private var childContainer: Container!

    override func setUp() {
        super.setUp()

        controlValue = Int.random(in: Int.min ... Int.max)
        let parentContainer = Container()
        parentContainer.register { TestInjectedType() }
        childContainer = Container(parent: parentContainer)
    }

    func testSimpleRegistration() throws {
        let value: TestInjectedType? = try childContainer.resolve()
        XCTAssertNotNil(value, "Could not resolve value")
    }
}
