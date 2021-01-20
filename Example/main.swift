//
// Example
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

import Foundation
import Macaroni

protocol MyService {
    var testValue: String { get }
}

class MyServiceImplementation: MyService {
    var testValue: String = "Yes!"
}

class ClassService1 {}
class ClassService2 {}

class MyContainerFactory: SingletonContainerFactory {
    override func build() -> Container {
        let container = SimpleContainer()
        let myService = MyServiceImplementation()
        let classService1 = ClassService1()
        let classService2 = ClassService2()
        container.register { () -> MyService in myService }
        container.register { () -> ClassService1 in classService1 }
        container.register { () -> ClassService2 in classService2 }
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
    @Injected
    var myForceUnwrappedOptionalService: MyService!
    @Injected
    var myOptionalService: MyService?

    func testInjection() {
        print("Does it work? \(myService.testValue)")
        print("Does it work force-unwrapped optionally? \(myForceUnwrappedOptionalService.testValue)")
        print("Does it work optionally? \(myOptionalService?.testValue ?? "NO!")")
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
            result.testValue = "Sure. :-)"
            return result
        }
    }

    func testInjection() {
        print("Does it work? \(myService.testValue)")
    }
}

let deferred = DeferredInitialization()
deferred.testInjection()


class ReferenceCounter {
    
    @Injected
    var strongServie: ClassService1?
    @WeakInjected
    var weakServie: ClassService2?
    
    func testInjection() {
        let service1RetainCount = CFGetRetainCount(strongServie!)
        let service2RetainCount = CFGetRetainCount(weakServie!)
        assert(service1RetainCount > service2RetainCount)
        print("Weak injection success!")
    }
}

let object = ReferenceCounter()
object.testInjection()
