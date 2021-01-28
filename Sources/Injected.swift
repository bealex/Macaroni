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
    public var wrappedValue: T {
        get { fatalError("Injecting only works for class enclosing types") }
        // We need setter here so that KeyPaths in subscript were writable.
        set { fatalError("Injecting only works for class enclosing types") }
    }

    private let scope: Scope
    private let initializer: ((Container) -> T)?

    public init(from scope: Scope = Scope.default) {
        self.scope = scope
        initializer = nil
    }

    public init(from scope: Scope = Scope.default, _ initializer: @escaping (Container) -> T) {
        self.scope = scope
        self.initializer = initializer
    }

    // MARK: - Parametrized option

    private var storage: T?

    public static subscript<EnclosingType>(
        _enclosingInstance instance: EnclosingType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingType, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingType, Self>
    ) -> T {
        get {
            var enclosingValue = instance[keyPath: storageKeyPath]
            if let value = enclosingValue.storage {
                return value
            } else {
                let container = enclosingValue.scope.container
                if let initializer = enclosingValue.initializer {
                    let value = initializer(container)
                    enclosingValue.storage = value
                    return value
                } else {
                    if let value: T = (try? container.resolve(parameter: instance)) ?? (try? container.resolve()) {
                        enclosingValue.storage = value
                        return value
                    } else {
                        let valueType = String(describing: T.self)
                        let enclosingType = String(describing: type(of: instance))
                        fatalError("Can't inject value of type \"\(valueType)\" into object of type \"\(enclosingType)\"")
                    }
                }
            }
        }
        set {
            // compiler needs this. We do not.
        }
    }
}
