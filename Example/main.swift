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
    var testValue: String = "It works! Tasty!"
}

class MyContainerFactory: SingletonContainerFactory {
    override func build() -> Container {
        let container = SimpleContainer()
        let myService = MyServiceImplementation()
        container.register { () -> MyService in myService }
        return container
    }
}

extension Scope {
    static let application = Scope(factory: MyContainerFactory())

    static func create() {
        self.default = application
    }
}

class MyController {
    @Injected
    var myService: MyService

    func testInjection() {
        print("Does it work? \(myService.testValue)")
    }
}

Scope.create()

let controller = MyController()
controller.testInjection()

class DeferredInitialization {
    @InjectedWithSetup
    var myService: MyService!

    init() {
        _myService.setup { container in
            let result = MyServiceImplementation()
            result.testValue = "It will work here as well. :-)"
            return result
        }
    }

    func testInjection() {
        print("Does it work? \(myService.testValue)")
    }
}

let deferred = DeferredInitialization()
deferred.testInjection()
