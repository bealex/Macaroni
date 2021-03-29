//
// InjectedFrom
// Macaroni
//
// Created by Alex Babaev on 29 March 2021.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

@propertyWrapper
public struct InjectedFrom<Value> {
    public var wrappedValue: Value { value }

    private let container: Container
    private let value: Value

    init(container: Container) {
        self.container = container

        do {
            if let value: Value = try container.resolve() {
                self.value = value
            } else {
                let valueType = String(describing: Value.self)
                Macaroni.handleError("Dependency \"\(valueType)\" is nil")
            }
        } catch {
            let valueType = String(describing: Value.self)
            Macaroni.handleError("Dependency \"\(valueType)\" does not have a resolver")
        }
    }
}
