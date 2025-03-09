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
public final class Container {
    let name: String
    let parent: Container?

    private static var counter: Int = 1
    private let queue: DispatchQueue

    /// you can lock container in case it will not be updated anymore.
    /// This should speed up container access, but remove ability to add new resolvers.
    private var isLocked: Bool = false

    public init(
        parent: Container? = nil,
        name: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) {
        self.parent = parent
        self.name = name ?? "UnnamedContainer.\(Container.counter)"
        queue = DispatchQueue(label: "container.\(self.name)", attributes: [ .concurrent ])

        Container.counter += 1
        Macaroni.logger.debug(
            message: "\(self.name)\(self.parent == nil ? "" : " (parent: \(parent?.name ?? "???"))") created",
            file: file, function: function, line: line
        )
    }

    public func lock() {
        queue.sync {
            isLocked = true
        }
    }

    public func unlock() {
        queue.sync {
            isLocked = false
        }
    }

    /// Resolvers that can create object by type.
    private var typeResolvers: [ObjectIdentifier: [String: () -> Any]] = [:]
    /// Resolvers that can create object, based on type and some arbitrary parameter.
    /// What is this parameter, depends on the usage.
    private var typeParametrizedResolvers: [ObjectIdentifier: [String: (_ parameter: Any) -> Any]] = [:]

    private func keys<D>(_ type: D.Type, alternative: String?) -> (ObjectIdentifier, String?) {
        (ObjectIdentifier(type), alternative)

//        if let alternative {
//            "\(String(reflecting: type))\(alternative)"
//        } else {
//            String(reflecting: type)
//        }
    }

    private let defaultAlternativeKey: String = "__default"

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

    /// Returns true, if type is resolvable with the container or its parent.
    public func isResolvable<D>(_ type: D.Type, alternative: String? = nil) -> Bool {
        queue.sync {
            let objectId = ObjectIdentifier(type)
            return parametrizedResolver(ObjectIdentifier(type), alternative: alternative) != nil ||
                    resolver(ObjectIdentifier(type), alternative: alternative) != nil || (parent?.isResolvable(type) ?? false)
        }
    }

    /// Registers resolving closure for type `D`.
    public func register<D>(
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping () -> D
    ) {
        guard !isLocked else { return assertionFailure("Container is locked") }

        let alternativeKey = alternative ?? defaultAlternativeKey
        queue.async(flags: .barrier) { [self] in
            let nonOptionalObjectId = ObjectIdentifier(D.self)
            let optionalObjectId = ObjectIdentifier(Optional<D>.self)
            typeResolvers[nonOptionalObjectId, default: [:]][alternativeKey] = resolver

            if self.resolver(optionalObjectId, alternative: alternativeKey) == nil && parametrizedResolver(optionalObjectId, alternative: alternativeKey) == nil {
                typeResolvers[optionalObjectId, default: [:]][alternativeKey] = resolver
                Macaroni.logger.debug(
                    message: "\(name) is registering resolver for \(String(describing: D.self)) and its Optional\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            } else {
                Macaroni.logger.debug(
                    message: "\(name) is registering resolver for \(String(describing: D.self))\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            }
        }
    }

    /// Registers resolving closure with parameter for type `D`. `@Injected` annotation sends enclosing object as a parameter.
    public func register<D>(
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line,
        _ resolver: @escaping (_ parameter: Any) -> D
    ) {
        guard !isLocked else { return assertionFailure("Container is locked") }

        let alternativeKey = alternative ?? defaultAlternativeKey
        queue.async(flags: .barrier) { [self] in
            let nonOptionalObjectId = ObjectIdentifier(D.self)
            let optionalObjectId = ObjectIdentifier(Optional<D>.self)
            typeParametrizedResolvers[nonOptionalObjectId, default: [:]][alternativeKey] = resolver

            if self.resolver(optionalObjectId, alternative: alternativeKey) == nil && parametrizedResolver(optionalObjectId, alternative: alternativeKey) == nil {
                typeParametrizedResolvers[optionalObjectId, default: [:]][alternativeKey] = resolver
                Macaroni.logger.debug(
                    message: "\(name) is registering parametrized resolver for \(String(describing: D.self)) and its Optional\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            } else {
                Macaroni.logger.debug(
                    message: "\(name) is registering parametrized resolver for \(String(describing: D.self))\(alternative.map { " / \($0)" } ?? "")",
                    file: file, function: function, line: line
                )
            }
        }
    }

    /// Returns instance of type `D`, if it is registered.
    public func resolve<D>(
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D {
        let objectId = ObjectIdentifier(D.self)
        let resolver = isLocked
            ? resolver(objectId, alternative: alternative)
            : queue.sync { self.resolver(objectId, alternative: alternative) }
        if let resolver {
            return resolver() as! D
        } else if let parent = self.parent {
            return try parent.resolve(alternative: alternative)
        } else {
            throw MacaroniError.noResolver
        }
    }

    /// Returns instance of type `D`, if it is registered. Sends `parameter` to the resolver.
    /// For example, parameter can be a class name that encloses value that needs to be injected.
    public func resolve<D>(
        parameter: Any,
        alternative: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) throws -> D {
        let objectId = ObjectIdentifier(D.self)
        let resolver = isLocked
            ? parametrizedResolver(objectId, alternative: alternative)
            : queue.sync { self.parametrizedResolver(objectId, alternative: alternative) }
        if let resolver {
            return resolver(parameter) as! D
        } else if let parent = self.parent {
            return try parent.resolve(parameter: parameter, alternative: alternative, file: file, function: function, line: line)
        } else {
            throw MacaroniError.noResolver
        }
    }

    /// Removes all resolvers.
    public func cleanup(file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        queue.async(flags: .barrier) { [self] in
            typeResolvers = [:]
            typeParametrizedResolvers = [:]
            Macaroni.logger.debug(message: "\(name) cleared", file: file, function: function, line: line)
        }
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
