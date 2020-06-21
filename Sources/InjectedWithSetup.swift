//
// InjectedWithSetup
// Macaroni
//
// Created by Alex Babaev on 21 June 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

@propertyWrapper
public struct InjectedWithSetup<T> {
    public private(set) var wrappedValue: T!
    private let scope: Scope

    public init(from scope: Scope = Scope.default) {
        self.scope = scope
    }

    mutating public func setup(_ laterInitializer: (Container) -> T?) {
        wrappedValue = laterInitializer(scope.container)
    }
}
