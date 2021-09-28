//
// Injected
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

private extension Container {
    static let alwaysFailRootContainerName: String = "_alwaysFailContainersDeriveFromThis"
    static let alwaysFailRootContainer: Container = Container(name: alwaysFailRootContainerName)

    // TODO: Maybe cache these results? Need a test.
    static func alwaysFailResolver<D>() -> Container.Resolver<D> { .init(container: Container(parent: Container.alwaysFailRootContainer)) }
}

@propertyWrapper
public struct Injected<Value> {
    public var wrappedValue: Value {
        get {
            if let value = storage {
                return value
            } else {
                Macaroni.logger.deathTrap("Injected value is nil")
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
    public private(set) var projectedValue: Container.Resolver<Value>

    // This works only for lazy initialization
    private var alternative: RegistrationAlternative?
    private var storage: Value?

    // Is used for class property injection. Lazy initialization if container is not present, eager otherwise.
    public init(alternative: RegistrationAlternative? = nil, container: Container? = nil) {
        if let container = container {
            // eager initialization
            projectedValue = container.resolved(alternative: alternative?.name)
            resolveRightNowIfPossible()
            Macaroni.logger.debug("Injecting (eager, container): \(String(describing: Value.self))")
        } else {
            // lazy initialization, wrapped value will be determined using subscript.
            self.alternative = alternative
            projectedValue = Container.alwaysFailResolver()
            Macaroni.logger.debug("Injecting (lazy): \(String(describing: Value.self))")
        }
    }

    public init(resolver: Container.Resolver<Value>) {
        projectedValue = resolver
        resolveRightNowIfPossible()
        Macaroni.logger.debug("Injecting (eager, resolver): \(String(describing: Value.self))")
    }

    public init(wrappedValue: Value) {
        storage = wrappedValue
        projectedValue = Container.alwaysFailResolver()
        Macaroni.logger.debug("Injecting (eager, value): \(String(describing: Value.self))")
    }

    // Is used for function parameter injection.
    public init(projectedValue: Container.Resolver<Value>) {
        self.projectedValue = projectedValue
        resolveRightNowIfPossible()
        Macaroni.logger.debug("Injecting (eager, projected): \(String(describing: Value.self))")
    }

    // TODO: Possibly allow usage of `.singleton` and/or `.fromEnclosingObject` container search policies

    private mutating func resolveRightNowIfPossible() {
        do {
            storage = try projectedValue.resolve()
        } catch {
            if projectedValue.resolvable(Value.self) {
                Macaroni.logger.deathTrap("Parametrized resolvers are not supported for greedy injection (\"\(String(describing: Value.self))\").")
            } else {
                Macaroni.logger.deathTrap("Dependency \"\(String(describing: Value.self))\" does not have a resolver")
            }
        }
        Macaroni.logger.debug("Injecting (eager, container): \(String(describing: Value.self))")
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
                Macaroni.logger.debug(
                    "Resolving " + "\(wrappedKeyPath)"
                        .replacingOccurrences(of: "Swift.ReferenceWritableKeyPath<", with: "")
                        .replacingOccurrences(of: ">", with: "")
                        .replacingOccurrences(of: ", ", with: "<-")
                )
                let alternative = instance[keyPath: storageKeyPath].alternative
                let value: Value = Container.resolve(for: instance, option: alternative?.name)
                instance[keyPath: storageKeyPath].storage = value
                return value
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
}
