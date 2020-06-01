//
// Injected
// Macaroni
//
// Created by Alex Babaev on 29 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

@propertyWrapper
public struct Injected<T> {
    public private(set) var wrappedValue: T

    public init(from scope: Scope = Scope.default) {
        self.wrappedValue = scope.container.resolveOrDie()
    }

    public init(from scope: Scope = Scope.default, _ initializer: (Container) -> T) {
        self.wrappedValue = initializer(scope.container)
    }
}
