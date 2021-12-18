//
// Injected
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

private extension Container {
    static let alwaysFailRootContainer: Container = Container(name: "_alwaysFailContainersDeriveFromThis")

    // TODO: Maybe cache these results? Need a test.
    static func alwaysFailResolver<D>() -> Container.Resolver<D> { .init(container: Container.alwaysFailRootContainer) }
}

@propertyWrapper
public struct Injected<Value> {
    public enum ContainerFindPolicyCapture {
        case onInitialization(ContainerLookupPolicy)
        case onFirstUsage

        var policy: ContainerLookupPolicy? {
            switch self {
                case .onInitialization(let policy): return policy
                case .onFirstUsage: return Container.lookupPolicy
            }
        }
    }

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

    // This works only for lazy initialization.
    private var alternative: RegistrationAlternative?
    private var storage: Value?

    // We need to strongly handle policy to be able to resolve lazily.
    private var findPolicyCapture: ContainerFindPolicyCapture = .onFirstUsage

    // Is used for class property injection. Lazy initialization if container is not present, eager otherwise.
    public init(
        alternative: RegistrationAlternative? = nil, container: Container? = nil, captureContainerLookupNow: Bool = true,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        self.alternative = alternative
        if let container = container {
            // eager initialization
            projectedValue = container.resolved(alternative: alternative?.name)
            resolveRightNowIfPossible(file: file, function: function, line: line)
            Macaroni.logger.debug("Injecting (eager from container): \(String(describing: Value.self))\(alternative.map { "/\($0.name)" } ?? "")", file: file, function: function, line: line)
        } else {
            // lazy initialization, wrapped value will be determined using subscript.
            projectedValue = Container.alwaysFailResolver()
            if let container = container {
                findPolicyCapture = .onInitialization(SingletonContainer(container))
            } else if captureContainerLookupNow {
                if let policy = Container.lookupPolicy {
                    findPolicyCapture = .onInitialization(policy)
                } else {
                    Macaroni.logger.deathTrap("Container.lookupPolicy is not initialized", file: file, function: function, line: line)
                }
            }
            Macaroni.logger.debug("Injecting (lazy): \(String(describing: Value.self))\(alternative.map { "/\($0.name)" } ?? "")", file: file, function: function, line: line)
        }
    }

    public init(resolver: Container.Resolver<Value>, file: String = #fileID, function: String = #function, line: UInt = #line) {
        projectedValue = resolver
        resolveRightNowIfPossible(file: file, function: function, line: line)
        Macaroni.logger.debug("Injecting (eager, resolver): \(String(describing: Value.self))", file: file, function: function, line: line)
    }

    public init(wrappedValue: Value, file: String = #fileID, function: String = #function, line: UInt = #line) {
        storage = wrappedValue
        projectedValue = Container.alwaysFailResolver()
        Macaroni.logger.debug("Injecting (eager, value): \(String(describing: Value.self))", file: file, function: function, line: line)
    }

    // Is used for function parameter injection.
    public init(projectedValue: Container.Resolver<Value>, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.projectedValue = projectedValue
        resolveRightNowIfPossible(file: file, function: function, line: line)
        Macaroni.logger.debug("Injecting (eager, projected): \(String(describing: Value.self))", file: file, function: function, line: line)
    }

    private mutating func resolveRightNowIfPossible(file: String = #fileID, function: String = #function, line: UInt = #line) {
        // TODO: Possibly allow usage of `.singleton` and/or `.fromEnclosingObject` container search policies
        do {
            storage = try projectedValue.resolve()
        } catch {
            if projectedValue.resolvable(Value.self) {
                Macaroni.logger.deathTrap("Parametrized resolvers are not supported for greedy injection (\"\(String(describing: Value.self))\").", file: file, function: function, line: line)
            } else {
                Macaroni.logger.deathTrap("Dependency \"\(String(describing: Value.self))\" does not have a resolver", file: file, function: function, line: line)
            }
        }
        Macaroni.logger.debug("Injecting (eager, container): \(String(describing: Value.self))", file: file, function: function, line: line)
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
                let alternative = instance[keyPath: storageKeyPath].alternative
                Macaroni.logger.debug("Resolving \(String(describing: EnclosingType.self)).…: \(String(describing: Value.self))\(alternative.map { "/\($0.name)" } ?? "")")
                guard let findPolicy = instance[keyPath: storageKeyPath].findPolicyCapture.policy else {
                    Macaroni.logger.deathTrap("Can't find container for \(String(describing: Value.self))\(alternative.map { ":\($0.name)" } ?? "") to \(String(describing: EnclosingType.self))")
                }

                let value: Value = findPolicy.resolve(for: instance, option: alternative?.name)
                instance[keyPath: storageKeyPath].storage = value
                return value
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
}
