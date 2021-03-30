//
// Injected
// Macaroni
//
// Created by Alex Babaev on 29 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

@propertyWrapper
public struct Injected<Value> {
    public var wrappedValue: Value {
        get { Macaroni.logger.errorAndDie("Injecting only works for class enclosing types") }
        // We need setter here so that KeyPaths in subscript were writable.
        set { Macaroni.logger.errorAndDie("Injecting only works for class enclosing types") }
    }

    public init() {
    }

    private var storage: Value?

    public static subscript<EnclosingType>(
        _enclosingInstance instance: EnclosingType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingType, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingType, Self>
    ) -> Value {
        get {
            var enclosingValue = instance[keyPath: storageKeyPath]
            if let value = enclosingValue.storage {
                return value
            } else {
                if let value: Value = Container.resolve(for: instance) {
                    enclosingValue.storage = value
                    return value
                } else {
                    Macaroni.logger.errorAndDie("Dependency \"\(String(describing: Value.self))\" is nil")
                }
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
}
