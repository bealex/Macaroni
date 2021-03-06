import XCTest
@testable import Macaroni

class ContainerSelectorTests: XCTestCase {
    private class TestInjectedType {}

    class MyController1 {
        @Injected
        var string: String
    }

    class MyController2 {
        @Injected
        var string: String
    }

    func testDefaultScope() throws {
        let checkStringScope1 = "String for scope 1"
        let checkStringScope2 = "String for scope 2"

        let defaultContainer = Container()
        let container1 = Container()
        let container2 = Container()
        container1.register { () -> String in checkStringScope1 }
        container2.register { () -> String in checkStringScope2 }

        Container.policy = .custom { enclosingObject in
            switch enclosingObject {
                case is MyController1: return container1
                case is MyController2: return container2
                default: return defaultContainer
            }
        }

        let myController1 = MyController1()
        let myController2 = MyController2()

        XCTAssertEqual(myController1.string, checkStringScope1)
        XCTAssertEqual(myController2.string, checkStringScope2)
    }
}
