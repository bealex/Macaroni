//
// DependencyInjection
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public enum ContainerError: Error {
    /// No resolvers was found for the type.
    case noResolver
}

/// Dependency injection container, that can create objects from their type.
public final class Container {
    private let parent: Container?

    public init(parent: Container? = nil) {
        self.parent = parent
    }

    /// Resolvers that can create object by type.
    private var typeResolvers: [String: () -> Any] = [:]
    /// Resolvers that can create object, based on type and some arbitrary parameter. What is this parameter, depends on the usage.
    private var typeParametrizedResolvers: [String: (_ parameter: Any) -> Any] = [:]

    /// Returns instance of type `D`, if it is registered.
    public func resolve<D>() throws -> D? {
        let key = self.key(D.self)
        if let resolver = typeResolvers[key] {
            return resolver() as? D
        } else if let parent = parent {
            return try parent.resolve()
        } else {
            throw ContainerError.noResolver
        }
    }

    /// Returns instance of type `D`, if it is registered. Sends `parameter` to the resolver.
    /// For example, parameter can be a class name that encloses value that needs to be injected.
    public func resolve<D>(parameter: Any) throws -> D? {
        let key = self.key(D.self)
        if let resolver = typeParametrizedResolvers[key] {
            return try resolver(parameter) as? D ?? parent?.resolve(parameter: parameter)
        } else if let parent = parent {
            return try parent.resolve(parameter: parameter)
        } else {
            throw ContainerError.noResolver
        }
    }

    /// Registers resolving closure for type `D`.
    public func register<D>(_ resolver: @escaping () -> D) {
        typeResolvers[key(D.self)] = resolver
        let optionalKey = key(Optional<D>.self)
        if typeResolvers[optionalKey] == nil && typeParametrizedResolvers[optionalKey] == nil {
            typeResolvers[optionalKey] = resolver
        }
    }

    /// Registers resolving closure with parameter for type `D`. `@Injected` annotation sends enclosing object as a parameter.
    public func register<D>(_ resolver: @escaping (_ parameter: Any) -> D) {
        typeParametrizedResolvers[key(D.self)] = resolver
        let optionalKey = key(Optional<D>.self)
        if typeResolvers[optionalKey] == nil && typeParametrizedResolvers[optionalKey] == nil {
            typeParametrizedResolvers[key(Optional<D>.self)] = resolver
        }
    }

    /// Removes all resolvers.
    public func cleanup() {
        typeResolvers = [:]
        typeParametrizedResolvers = [:]
    }

    private func key<D>(_ type: D.Type) -> String {
        String(reflecting: type)
    }
}
