//
// DependencyInjection
// Macaroni
//
// Created by Alex Babaev on 30 May 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

public enum MacaroniError: Error {
    /// No resolvers was found for the type.
    case noResolver
}

private class AtomicCounter: @unchecked Sendable {
    private let queue = DispatchQueue(label: "Macaroni.AtomicCounter")
    private var value: Int

    init(_ initial: Int) { value = initial }

    func next() -> Int {
        queue.sync {
            let current = value
            value += 1
            return current
        }
    }
}

private class ContainerStorage: @unchecked Sendable {
    private let queue: DispatchQueue
    private var isLocked: Bool = false

    private let defaultAlternativeKey: String = "__default"
    private var typeResolvers: [ObjectIdentifier: [String: () -> Any]] = [:]
    private var typeParametrizedResolvers: [ObjectIdentifier: [String: (_ parameter: Any) -> Any]] = [:]

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func lock() {
        queue.sync { isLocked = true }
    }

    func unlock() {
        queue.sync { isLocked = false }
    }

    private func resolver(_ objectId: ObjectIdentifier, alternative: String?) -> (() -> Any)? {
        if let alternative {
            return typeResolvers[objectId]?[alternative]
        } else {
            return typeResolvers[objectId]?[defaultAlternativeKey]
        }
    }

    private func parametrizedResolver(_ objectId: ObjectIdentifier, alternative: String?) -> ((_ parameter: Any) -> Any)? {
        if let alternative {
            return typeParametrizedResolvers[objectId]?[alternative]
        } else {
            return typeParametrizedResolvers[objectId]?[defaultAlternativeKey]
        }
    }

    func isResolvable<D>(_ type: D.Type, alternative: String?, parent: Container?) -> Bool {
        queue.sync {
            let objectId = ObjectIdentifier(type)
            return parametrizedResolver(objectId, alternative: alternative) != nil ||
                    resolver(objectId, alternative: alternative) != nil || (parent?.isResolvable(type) ?? false)
        }
    }

    func register<D>(
        alternative: String?,
        file: StaticString, function: String, line: UInt,
        containerName: String,
        _ resolverClosure: @escaping () -> D
    ) {
        guard !isLocked else { return assertionFailure("Container is locked") }

        let alternativeKey = alternative ?? defaultAlternativeKey
        queue.sync(flags: .barrier) { [self] in
            let nonOptionalObjectId = ObjectIdentifier(D.self)
            let optionalObjectId = ObjectIdentifier(Optional<D>.self)
            typeResolvers[nonOptionalObjectId, default: [:]][alternativeKey] = resolverClosure

            if resolver(optionalObjectId, alternative: alternativeKey) == nil && parametrizedResolver(optionalObjectId, alternative: alternativeKey) == nil {
                typeResolvers[optionalObjectId, default: [:]][alternativeKey] = resolverClosure
                Macaroni.logger.debug(
                    message: "\(containerName) is registering resolver for \(String(describing: D.self)) and its Optional\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            } else {
                Macaroni.logger.debug(
                    message: "\(containerName) is registering resolver for \(String(describing: D.self))\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            }
        }
    }

    func register<D>(
        alternative: String?,
        file: StaticString, function: String, line: UInt,
        containerName: String,
        _ resolverClosure: @escaping (_ parameter: Any) -> D
    ) {
        guard !isLocked else { return assertionFailure("Container is locked") }

        let alternativeKey = alternative ?? defaultAlternativeKey
        queue.sync(flags: .barrier) { [self] in
            let nonOptionalObjectId = ObjectIdentifier(D.self)
            let optionalObjectId = ObjectIdentifier(Optional<D>.self)
            typeParametrizedResolvers[nonOptionalObjectId, default: [:]][alternativeKey] = resolverClosure

            if resolver(optionalObjectId, alternative: alternativeKey) == nil && parametrizedResolver(optionalObjectId, alternative: alternativeKey) == nil {
                typeParametrizedResolvers[optionalObjectId, default: [:]][alternativeKey] = resolverClosure
                Macaroni.logger.debug(
                    message: "\(containerName) is registering parametrized resolver for \(String(describing: D.self)) and its Optional\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            } else {
                Macaroni.logger.debug(
                    message: "\(containerName) is registering parametrized resolver for \(String(describing: D.self))\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            }
        }
    }

    func resolve<D>(alternative: String?, parent: Container?) throws -> D {
        let objectId = ObjectIdentifier(D.self)
        let resolverClosure = isLocked
            ? resolver(objectId, alternative: alternative)
            : queue.sync { self.resolver(objectId, alternative: alternative) }
        if let resolverClosure {
            return resolverClosure() as! D
        } else if let parent {
            return try parent.resolve(alternative: alternative)
        } else {
            throw MacaroniError.noResolver
        }
    }

    func resolve<D>(parameter: Any, alternative: String?, parent: Container?, file: StaticString, function: String, line: UInt) throws -> D {
        let objectId = ObjectIdentifier(D.self)
        let resolverClosure = isLocked
            ? parametrizedResolver(objectId, alternative: alternative)
            : queue.sync { self.parametrizedResolver(objectId, alternative: alternative) }
        if let resolverClosure {
            return resolverClosure(parameter) as! D
        } else if let parent {
            return try parent.resolve(parameter: parameter, alternative: alternative, file: file, function: function, line: line)
        } else {
            throw MacaroniError.noResolver
        }
    }

    func cleanup(containerName: String, file: StaticString, function: String, line: UInt) {
        queue.async(flags: .barrier) { [self] in
            typeResolvers = [:]
            typeParametrizedResolvers = [:]
            Macaroni.logger.debug(message: "\(containerName) cleared", file: file, function: function, line: line)
        }
    }
}

/// Dependency injection container, that can resolve registered objects. Registration is done on type-by-type basis,
/// so that only one object can be resolved based on its type.
///
/// If you need to resolve several objects for one type, you need to use `alternatives`.
///
/// Usually if you register `Type`, you can resolve `Type?` and `Type!` as well.
///
/// Containers can have a hierarchy. If type is not found in current container, its resolving is delegated to the parent.
///
/// Containers have two resolver types. One does not know about anything but the type it is resolving. Another knows
/// the type of type that contains property that is being resolved.
///
/// There is a `@Injected` property wrapper that helps to inject objects into classes (mostly).
public final class Container: Sendable {
    let name: String
    let parent: Container?

    private static let counter = AtomicCounter(1)
    private let storage: ContainerStorage

    public init(
        parent: Container? = nil,
        name: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) {
        self.parent = parent
        let id = Container.counter.next()
        self.name = name ?? "UnnamedContainer.\(id)"
        let queue = DispatchQueue(label: "container.\(self.name)", attributes: [ .concurrent ])
        self.storage = ContainerStorage(queue: queue)
        Macaroni.logger.debug(
            message: "\(self.name)\(self.parent == nil ? "" : " (parent: \(parent?.name ?? "???"))") created",
            file: file, function: function, line: line
        )
    }

    public func lock() {
        storage.lock()
    }

    public func unlock() {
        storage.unlock()
    }

    /// Returns true, if type is resolvable with the container or its parent.
    public func isResolvable<D>(_ type: D.Type, alternative: String? = nil) -> Bool {
        storage.isResolvable(type, alternative: alternative, parent: parent)
    }

    /// Registers resolving closure for type `D`.
    public func register<D>(
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping () -> D
    ) {
        storage.register(alternative: alternative, file: file, function: function, line: line, containerName: name, resolver)
    }

    /// Registers resolving closure with parameter for type `D`. `@Injected` annotation sends enclosing object as a parameter.
    public func register<D>(
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping (_ parameter: Any) -> D
    ) {
        storage.register(alternative: alternative, file: file, function: function, line: line, containerName: name, resolver)
    }

    /// Returns instance of type `D`, if it is registered.
    public func resolve<D>(
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D {
        try storage.resolve(alternative: alternative, parent: parent)
    }

    /// Returns instance of type `D`, if it is registered. Sends `parameter` to the resolver.
    /// For example, parameter can be a class name that encloses value that needs to be injected.
    public func resolve<D>(
        parameter: Any,
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D {
        try storage.resolve(parameter: parameter, alternative: alternative, parent: parent, file: file, function: function, line: line)
    }

    /// Removes all resolvers.
    public func cleanup(file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        storage.cleanup(containerName: name, file: file, function: function, line: line)
    }
}

public extension Container {
    func register<D>(
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping () -> D
    ) {
        register(alternative: Optional<String>.none, file: file, function: function, line: line, resolver)
    }

    func register<D>(
        alternative: RegistrationAlternative? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping () -> D
    ) {
        register(alternative: alternative?.name, file: file, function: function, line: line, resolver)
    }

    func register<D>(
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping (_ parameter: Any) -> D
    ) {
        register(alternative: Optional<String>.none, file: file, function: function, line: line, resolver)
    }

    func register<D>(
        alternative: RegistrationAlternative? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping (_ parameter: Any) -> D
    ) {
        register(alternative: alternative?.name, file: file, function: function, line: line, resolver)
    }

    func resolve<D>(
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D? {
        try resolve(alternative: Optional<String>.none, file: file, function: function, line: line)
    }

    func resolve<D>(
        alternative: RegistrationAlternative? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D? {
        try resolve(alternative: alternative?.name, file: file, function: function, line: line)
    }

    func resolve<D>(
        parameter: Any,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D? {
        try resolve(parameter: parameter, alternative: Optional<String>.none, file: file, function: function, line: line)
    }

    func resolve<D>(
        parameter: Any, alternative: RegistrationAlternative? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D? {
        try resolve(parameter: parameter, alternative: alternative?.name, file: file, function: function, line: line)
    }
}
