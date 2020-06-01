//
// Example
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

// This is a simple example, how to use Macaroni.
import Macaroni

// 1. Create container factory, that can create container if Scope needs it.

class MyContainerFactory: SingletonContainerFactory {
    override func build() -> Container {
        let container = SimpleContainer()
        // 1.1. Let's register container itself as a dependency. :-)
        container.register { () -> Container in container }
        return container
    }
}

// 2. Extend Scope to create your own scopes.

extension Scope {
    static let application = Scope(factory: MyContainerFactory())

    static func create() {
        // 2.1. We have to set default scope if we want to simplify its usage.
        self.default = application
    }
}

// 3. Now let's use it!

class CoolCoordinator {
    // 3.1. You can specify scope here: `@Injected(from: .application)`
    // 3.2. You can use closure to create something using the container: `@Injected({ createFromContainer($0) })`
    @Injected
    var container: Container

    func useContainer() {
        print("Here is injected container: \(container)")
    }
}

// 4. Small test.

// 4.1 Create scopes
Scope.create()

// 4.1 Initialize example class and run it
let coordinator = CoolCoordinator()
coordinator.useContainer()
