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

    public enum InitializationKind {
        /// Will find container and resolve the value on first access. Useful for "late initialization".
        case lazily
        /// Will capture container when initializing, resolve value on first access. If container is specified, it is used for resolve.
        case fromContainer(Container? = nil)
        /// Will capture container when initializing and resolve the value on initializing. If container is specified, it is used for resolve.
        case immediate(Container? = nil)
    }

    public var wrappedValue: Value {
        get {
            if let value = storage {
                return value
            } else {
                Macaroni.logger.die("Injected value is nil")
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
        _ initialization: InitializationKind = .fromContainer(),
        alternative: RegistrationAlternative? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) {
        self.alternative = alternative
        switch initialization {
            case .immediate(let container):
                projectedValue = Container.alwaysFailResolver()
                guard let container = container ?? Container.lookupPolicy?.container(for: Self.self, file: file, function: function, line: line) else {
                    Macaroni.logger.die("Can't find container for Injected immediateResolve", file: file, function: function, line: line)
                }

                projectedValue = container.resolved(alternative: alternative?.name)
                resolveRightNowIfPossible(file: file, function: function, line: line)
            case .fromContainer(let container):
                if let container = container {
                    projectedValue = Container.alwaysFailResolver()
                    findPolicyCapture = .onInitialization(.singleton(container))
                } else if let policy = Container.lookupPolicy {
                    projectedValue = Container.alwaysFailResolver()
                    findPolicyCapture = .onInitialization(policy)
                } else {
                    Macaroni.logger.die("Container.lookupPolicy is not initialized", file: file, function: function, line: line)
                }
            case .lazily:
                projectedValue = Container.alwaysFailResolver()
                findPolicyCapture = .onFirstUsage
                Macaroni.logger.debug("Injecting (lazy): \(String(describing: Value.self))\(alternative.map { "/\($0.name)" } ?? "")", file: file, function: function, line: line)
        }
    }

    public init(resolver: Container.Resolver<Value>, file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        projectedValue = resolver
        resolveRightNowIfPossible(file: file, function: function, line: line)
        Macaroni.logger.debug("Injecting (eager, resolver): \(String(describing: Value.self))", file: file, function: function, line: line)
    }

    public init(wrappedValue: Value, file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        storage = wrappedValue
        projectedValue = Container.alwaysFailResolver()
        Macaroni.logger.debug("Injecting (eager, value): \(String(describing: Value.self))", file: file, function: function, line: line)
    }

    // Is used for function parameter injection.
    public init(projectedValue: Container.Resolver<Value>, file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        self.projectedValue = projectedValue
        resolveRightNowIfPossible(file: file, function: function, line: line)
        Macaroni.logger.debug("Injecting (eager, projected): \(String(describing: Value.self))", file: file, function: function, line: line)
    }

    private mutating func resolveRightNowIfPossible(file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        // TODO: Possibly allow usage of `.singleton` and/or `.enclosingType` container search policies
        do {
            storage = try projectedValue.resolve()
            Macaroni.logger.debug("Injecting (eager from container): \(String(describing: Value.self))\(alternative.map { "/\($0.name)" } ?? "")", file: file, function: function, line: line)
        } catch {
            if projectedValue.isResolvable(Value.self) {
                Macaroni.logger.die("Parametrized resolvers are not supported for greedy injection (\"\(String(describing: Value.self))\").", file: file, function: function, line: line)
            } else {
                Macaroni.logger.die("Dependency \"\(String(describing: Value.self))\" does not have a resolver", file: file, function: function, line: line)
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
                let alternative = instance[keyPath: storageKeyPath].alternative
                Macaroni.logger.debug("Resolving \(String(describing: EnclosingType.self)).…: \(String(describing: Value.self))\(alternative.map { "/\($0.name)" } ?? "")")
                guard let findPolicy = instance[keyPath: storageKeyPath].findPolicyCapture.policy else {
                    Macaroni.logger.die("Can't find container for \(String(describing: Value.self))\(alternative.map { ":\($0.name)" } ?? "") to \(String(describing: EnclosingType.self))")
                }

                let value: Value = findPolicy.resolve(for: instance, option: alternative?.name)
                instance[keyPath: storageKeyPath].storage = value
                return value
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
}
