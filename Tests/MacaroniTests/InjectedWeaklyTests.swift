import XCTest
@testable import Macaroni

private let testStringValue: String = "Yes Service!"

private protocol MyService: AnyObject {}
private class MyServiceImplementation: MyService {}

private class MyController {
    @InjectedWeakly
    var myService: MyService?
}

class InjectedWeaklyTests: XCTestCase {
    static let container = Container()

    override class func setUp() {
        Container.policy = .singleton(container)
    }

    override func setUp() {
        Self.container.cleanup()
    }

    func testWeaklyInjected() {
        let register: () -> MyService = {
            let service: MyService = MyServiceImplementation()
            Self.container.register { [weak service] in service }
            return service
        }

        var service: MyService? = register()
        print("(just need to silence warning) \(String(describing: service))")
        let testObject = MyController()
        XCTAssertNotNil(testObject.myService)
        service = nil
        XCTAssertNil(testObject.myService)
    }

    func testWeaklyNilInjected() {
        Self.container.register { () -> MyService? in nil }

        let testObject = MyController()
        XCTAssertNil(testObject.myService)
    }
}
