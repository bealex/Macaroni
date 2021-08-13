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

    public init(container: Container, alternative: RegistrationAlternative? = nil) {
        self.container = container

        do {
            if let value: Value = try container.resolve(alternative: alternative?.name) {
                self.value = value
            } else {
                Macaroni.logger.errorAndDie("Dependency \"\(String(describing: Value.self))\" is nil")
            }
        } catch {
            if container.resolvable(Value.self) {
                Macaroni.logger.errorAndDie("Parametrized resolvers are not supported for @InjectedFrom (\"\(String(describing: Value.self))\").")
            } else {
                Macaroni.logger.errorAndDie("Dependency \"\(String(describing: Value.self))\" does not have a resolver")
            }
        }
    }
}
