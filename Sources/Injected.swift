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

    public init() {
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
                let container = ContainerSelector.for(instance)
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
        set {
            // compiler needs this. We do not.
        }
    }
}
