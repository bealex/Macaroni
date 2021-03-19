import XCTest
@testable import Macaroni

class ParentContainerTests: XCTestCase {
    private class TestInjectedType {}

    private var controlValue: Int!
    private var childContainer: Container!

    override func setUp() {
        super.setUp()

        let container = Container()
        controlValue = Int.random(in: Int.min ... Int.max)
        container.register { TestInjectedType() }

        childContainer = Container(parent: container)
    }

    func testSimpleRegistration() throws {
        let value: TestInjectedType? = try childContainer.resolve()
        XCTAssertNotNil(value, "Could not resolve value")
    }
}
