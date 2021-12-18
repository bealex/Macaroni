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
    public enum ContainerFindPolicyCapture {
        case onInitialization(ContainerFindable)
        case onFirstUsage

        var policy: ContainerFindable? {
            switch self {
                case .onInitialization(let policy): return policy
                case .onFirstUsage: return Container.policy
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
        if let container = container {
            // eager initialization
            projectedValue = container.resolved(alternative: alternative?.name)
            resolveRightNowIfPossible()
            Macaroni.logger.debug(
                "Injecting (eager, container): \(String(reflecting: Value.self))", file: file, function: function, line: line
            )
        } else {
            if let container = container {
                findPolicyCapture = .onInitialization(SingletonContainer(container))
            } else if captureContainerLookupNow {
                findPolicyCapture = .onInitialization(Container.policy)
            }

            // lazy initialization, wrapped value will be determined using subscript.
            self.alternative = alternative
            projectedValue = Container.alwaysFailResolver()
            Macaroni.logger.debug(
                "Injecting (lazy): \(String(reflecting: Value.self))", file: file, function: function, line: line
            )
        }
    }

    public init(resolver: Container.Resolver<Value>, file: String = #fileID, function: String = #function, line: UInt = #line) {
        projectedValue = resolver
        resolveRightNowIfPossible()
        Macaroni.logger.debug("Injecting (eager, resolver): \(String(reflecting: Value.self))", file: file, function: function, line: line)
    }

    public init(wrappedValue: Value, file: String = #fileID, function: String = #function, line: UInt = #line) {
        storage = wrappedValue
        projectedValue = Container.alwaysFailResolver()
        Macaroni.logger.debug("Injecting (eager, value): \(String(reflecting: Value.self))", file: file, function: function, line: line)
    }

    // Is used for function parameter injection.
    public init(projectedValue: Container.Resolver<Value>, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.projectedValue = projectedValue
        resolveRightNowIfPossible()
        Macaroni.logger.debug("Injecting (eager, projected): \(String(reflecting: Value.self))", file: file, function: function, line: line)
    }

    // TODO: Possibly allow usage of `.singleton` and/or `.fromEnclosingObject` container search policies

    private mutating func resolveRightNowIfPossible(file: String = #fileID, function: String = #function, line: UInt = #line) {
        do {
            storage = try projectedValue.resolve()
        } catch {
            if projectedValue.resolvable(Value.self) {
                Macaroni.logger.deathTrap(
                    "Parametrized resolvers are not supported for greedy injection (\"\(String(reflecting: Value.self))\").",
                    file: file, function: function, line: line
                )
            } else {
                Macaroni.logger.deathTrap(
                    "Dependency \"\(String(reflecting: Value.self))\" does not have a resolver", file: file, function: function, line: line
                )
            }
        }
        Macaroni.logger.debug("Injecting (eager, container): \(String(reflecting: Value.self))", file: file, function: function, line: line)
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
                guard let findPolicy = instance[keyPath: storageKeyPath].findPolicyCapture.policy else {
                    Macaroni.logger.deathTrap(
                        "Can't find container for \(String(reflecting: Value.self)) to \(String(reflecting: EnclosingType.self))"
                    )
                }

                let alternative = instance[keyPath: storageKeyPath].alternative
                let value: Value = findPolicy.resolve(for: instance, option: alternative?.name)
                instance[keyPath: storageKeyPath].storage = value
                return value
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
}
