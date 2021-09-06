//
// Injected
// Macaroni
//
// Created by Alex Babaev on 29 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public extension Container {
    static var emptyDefaultContainer: Container = Container(name: "emptyAndDefault")
}

@propertyWrapper
public struct Injected<Value> {
    public var wrappedValue: Value {
        get { storage! }
        set { storage = newValue }
    }
    public private(set) var projectedValue: Container

    private var alternative: RegistrationAlternative?
    private var storage: Value?

    // Is used for class property injection.
    public init(alternative: RegistrationAlternative? = nil, container: Container = .emptyDefaultContainer) {
        self.alternative = alternative
        projectedValue = container
        resolveRightNowIfPossible()
    }

    // Is used for function parameter injection.
    public init(wrappedValue: Value, alternative: RegistrationAlternative? = nil, container: Container = .emptyDefaultContainer) {
        storage = wrappedValue
        self.alternative = alternative
        projectedValue = container
        // this will override storage, so it is usually pointless to use this call with wrappedValue and container together
        resolveRightNowIfPossible()
    }

    // Is used for function parameter injection.
    public init(projectedValue: Container) {
        self.projectedValue = projectedValue
        resolveRightNowIfPossible()
    }

    private mutating func resolveRightNowIfPossible() {
        guard projectedValue !== Container.emptyDefaultContainer else { return }

        do {
            if let value: Value = try projectedValue.resolve(alternative: alternative?.name) {
                storage = value
            } else {
                Macaroni.logger.errorAndDie("Dependency \"\(String(describing: Value.self))\" is nil")
            }
        } catch {
            if projectedValue.resolvable(Value.self) {
                Macaroni.logger.errorAndDie("Parametrized resolvers are not supported for greedy injection (\"\(String(describing: Value.self))\").")
            } else {
                Macaroni.logger.errorAndDie("Dependency \"\(String(describing: Value.self))\" does not have a resolver")
            }
        }
    }

    /// Is called when injected into a class property and being accessed.
    public static subscript<EnclosingType>(
        _enclosingInstance instance: EnclosingType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingType, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingType, Self>
    ) -> Value {
        get {
            let enclosingValue = instance[keyPath: storageKeyPath]
            if let value = enclosingValue.storage {
                return value
            } else {
                let option = instance[keyPath: storageKeyPath].alternative
                if let value: Value = Container.resolve(for: instance, option: option?.name) {
                    instance[keyPath: storageKeyPath].storage = value
                    return value
                } else {
                    Macaroni.logger.errorAndDie("Dependency \"\(String(describing: Value.self))\" is nil")
                }
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
}
