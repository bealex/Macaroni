//
// Example
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

import Macaroni

protocol MyService {
    var testValue: String { get }
}

class MyServiceImplementation: MyService {
    var testValue: String = "Yes Service!"
}

class MyContainerFactory: SingletonContainerFactory {
    override func build() -> Container {
        let container = SimpleContainer()
        let myService = MyServiceImplementation()
        container.register { () -> MyService in myService }
        container.register { () -> String? in nil }
        container.register { (_ parameter: Any) -> String in "Yes! You've injected me into \(String(describing: type(of: parameter)))" }
        return container
    }
}

extension Scope {
    static let application = Scope(factory: MyContainerFactory())

    static func create() {
        `default` = application
    }
}

class MyController {
    @Injected
    var myService: MyService
    @Injected
    var myForceUnwrappedOptionalService: MyService!
    @Injected
    var myOptionalService: MyService?
    @Injected
    var myStringInitializingAfterInit: String
    @Injected
    var myOptionalString: String?

    func testInjection() {
        print("Does it work? \(myService.testValue)")
        print("Does it work force-unwrapped optionally? \(myForceUnwrappedOptionalService.testValue)")
        print("Does it work optionally? \(myOptionalService?.testValue ?? "NO!")")
        print("Can it use enclosed object? \(myStringInitializingAfterInit)")
        print("Does it work optionally with `nil` in container? \(myOptionalString ?? "Yes!")")
    }
}

Scope.create()

let controller = MyController()
controller.testInjection()
