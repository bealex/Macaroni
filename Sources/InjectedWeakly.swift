//
// InjectedWeakly
// Macaroni
//
// Created by Alex Babaev on 29 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

/// This wrapper can be used only with classes. You must capture injected object weakly (with [weak object]) in registration closure.
@propertyWrapper
public struct InjectedWeakly<Value> {
    public var wrappedValue: Value? {
        get { Macaroni.logger.errorAndDie("Injecting only works for class enclosing types") }
        // We need setter here so that KeyPaths in subscript were writable.
        set { Macaroni.logger.errorAndDie("Injecting only works for class enclosing types") }
    }

    public init() {
    }

    weak var storage: AnyObject?
    private var isResolved: Bool = false

    public static subscript<EnclosingType>(
        _enclosingInstance instance: EnclosingType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingType, Value?>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingType, Self>
    ) -> Value? {
        get {
            var enclosingValue = instance[keyPath: storageKeyPath]
            if enclosingValue.isResolved, let value = enclosingValue.storage as? Value {
                return value
            } else {
                if let value: Value? = Container.resolve(for: instance) {
                    enclosingValue.isResolved = true
                    enclosingValue.storage = value as AnyObject
                    return value
                } else {
                    enclosingValue.isResolved = true
                    enclosingValue.storage = nil
                    return nil
                }
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
}
