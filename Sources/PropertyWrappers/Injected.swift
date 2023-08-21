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
}

/// This property wrapper helps to use objects that were previously registered in the `Container`. It does two things:
///  - searches for the container. Usually it is using `Container.lookupPolicy` for that.
///  - asks the found container to resolve object based on the type `ValueType`.
///
/// Both actions can happen while enclosing object is being initialized or when the property is being accessed for the first time.
/// Initialization parameter determines when exactly. Only three options are available:
///  - `@Injected(.capturingContainerOnInit(Container?))` is the default option. It tries to capture container
///    during the initialization, but resolves property value later, when it is being accessed for the first time.
///  - `@Injected(.lazily)` means that both container lookup and property resolve are happening when property
///    is being accessed for the first time
///  - `@Injected(.resolvingOnInit(from: Container?))` tries to do everything right during the initialization.
///
/// You can also use `@Injected` in functions: `func test(@Injected value: String)`,
/// using it like this: `test($value: container.resolved())`.
@propertyWrapper
public struct Injected<ValueType> {
    enum ContainerCapturePolicy {
        case onInitialization(ContainerLookupPolicy)
        case onFirstUsage

        var policy: ContainerLookupPolicy? {
            switch self {
                case .onInitialization(let policy): return policy
                case .onFirstUsage: return Container.lookupPolicy
            }
        }
    }

    public enum ResolveFrom {
        case object(Any, alternative: String? = nil)
        case container(Container, alternative: String? = nil)
        case alreadyResolved(Any)
    }

    public enum InitializationKind {
        /// Will find container and resolve the value on first access. Useful for "late initialization".
        case lazily
        /// Will capture container when initializing, resolve value on first access. If container is specified, it is used for resolve.
        case capturingContainerOnInit(Container? = nil)
        /// Will capture container when initializing and resolve the value on initializing. If container is specified, it is used for resolve.
        case resolvingOnInit(from: Container? = nil)
    }

    public var wrappedValue: ValueType {
        get {
            if let value = storage {
                return value
            } else {
                Macaroni.logger.die("Injected value is nil")
            }
        }
        set { /* compiler needs this. We do not. */ }
    }
    public private(set) var projectedValue: ResolveFrom

    // This works only for lazy initialization.
    private var alternative: RegistrationAlternative?
    private var storage: ValueType?

    // We need to strongly handle policy to be able to resolve lazily.
    private var capturePolicy: ContainerCapturePolicy = .onFirstUsage

    // Is used for class property injection. Lazy initialization if container is not present, eager otherwise.
    public init(
        _ initialization: InitializationKind = .capturingContainerOnInit(),
        alternative: RegistrationAlternative? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) {
        self.alternative = alternative
        switch initialization {
            case .resolvingOnInit(let container):
                projectedValue = .container(Container.alwaysFailRootContainer)
                guard let container = container ?? Container.lookupPolicy?.container(for: Self.self, file: file, function: function, line: line) else {
                    Macaroni.logger.die("Can't find container for Injected immediateResolve", file: file, function: function, line: line)
                }

                projectedValue = .container(container, alternative: alternative?.name)
                resolveRightNowIfPossible(file: file, function: function, line: line)
            case .capturingContainerOnInit(let container):
                if let container = container {
                    projectedValue = .container(Container.alwaysFailRootContainer)
                    capturePolicy = .onInitialization(.singleton(container))
                } else if let policy = Container.lookupPolicy {
                    projectedValue = .container(Container.alwaysFailRootContainer)
                    capturePolicy = .onInitialization(policy)
                } else {
                    Macaroni.logger.die("Container.lookupPolicy is not initialized", file: file, function: function, line: line)
                }
            case .lazily:
                projectedValue = .container(Container.alwaysFailRootContainer)
                capturePolicy = .onFirstUsage
                Macaroni.logger.debug("Injecting (lazy): \(String(reflecting: ValueType.self))\(alternative.map { "/\($0.name)" } ?? "")", file: file, function: function, line: line)
        }
    }

    public init(wrappedValue: ValueType, file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        storage = wrappedValue
        projectedValue = .container(Container.alwaysFailRootContainer)
        Macaroni.logger.debug("Injecting (eager, value): \(String(reflecting: ValueType.self))", file: file, function: function, line: line)
    }

    // Is used for function parameter injection.
    public init(projectedValue: ResolveFrom, file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        self.projectedValue = projectedValue
        resolveRightNowIfPossible(file: file, function: function, line: line)
        Macaroni.logger.debug("Injecting (eager, projected): \(String(reflecting: ValueType.self))", file: file, function: function, line: line)
    }

    private mutating func resolveRightNowIfPossible(file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        switch projectedValue {
            case .alreadyResolved(let value):
                if let value = value as? ValueType {
                    storage = value
                    Macaroni.logger.debug(
                        "Injecting (eager from container): \(String(reflecting: ValueType.self))\(alternative.map { "/\($0.name)" } ?? "")",
                        file: file, function: function, line: line
                    )
                } else {
                    Macaroni.logger.die(
                        "Injected value is not of type \"\(String(reflecting: ValueType.self))\": (\(value))",
                        file: file, function: function, line: line
                    )
                }
            case .object(let enclosedObject, let alternative):
                let resolved: ValueType = Injected.resolve(for: enclosedObject, alternative: alternative, findPolicy: Container.lookupPolicy)
                storage = resolved
            case .container(let container, let alternative):
                do {
                    let resolved: ValueType = try container.resolve(alternative: alternative)
                    storage = resolved
                } catch {
                    Macaroni.logger.die(
                        "Can't find resolver for \"\(String(reflecting: ValueType.self))\" in container (\(container.name))",
                        file: file, function: function, line: line
                    )
                }
        }
    }

    /// Is called when injected into a class property and being accessed.
    public static subscript<EnclosingType>(
        _enclosingInstance instance: EnclosingType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingType, ValueType>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingType, Self>
    ) -> ValueType {
        get {
            let enclosingValue = instance[keyPath: storageKeyPath]
            if let value = enclosingValue.storage {
                return value
            } else {
                let alternative = instance[keyPath: storageKeyPath].alternative?.name
                let findPolicy = instance[keyPath: storageKeyPath].capturePolicy.policy
                let value = resolve(for: instance, alternative: alternative, findPolicy: findPolicy)
                instance[keyPath: storageKeyPath].storage = value
                return value
            }
        }
        set { /* compiler needs this. We do not. */ }
    }

    private static func resolve(
        for enclosingInstance: Any, alternative: String? = nil, findPolicy: ContainerLookupPolicy?,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> ValueType {
        Macaroni.logger.debug(
            "Resolving [\(String(reflecting: ValueType.self)) \(alternative.map { " / \($0)" } ?? "")] in the \(String(reflecting: type(of: enclosingInstance)))",
            file: file, function: function, line: line
        )
        guard let findPolicy else {
            Macaroni.logger.die(
                "Can't find container for [\(String(reflecting: ValueType.self))\(alternative.map { " / \($0)" } ?? "")] to \(String(reflecting: type(of: enclosingInstance)))",
                file: file, function: function, line: line
            )
        }

        return findPolicy.resolve(for: enclosingInstance, option: alternative)
    }
}
