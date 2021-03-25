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
public class Container {
    private let parent: Container?

    public init(parent: Container? = nil) {
        self.parent = parent
    }

    /// Resolvers that can create object by type.
    private var singletonTypeResolvers: [String: () -> Any] = [:]
    /// Resolvers that can create object, based on type and some arbitrary parameter. What is this parameter, depends on the usage.
    private var singletonTypeParametrizedResolvers: [String: (_ parameter: Any) -> Any] = [:]

    /// Returns instance of type `D`, if it is registered.
    public func resolve<D>() throws -> D? {
        if let resolver = singletonTypeResolvers[key(D.self)] {
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
        if let resolver = singletonTypeParametrizedResolvers[key(D.self)] {
            return try resolver(parameter) as? D ?? parent?.resolve(parameter: parameter)
        } else if let parent = parent {
            return try parent.resolve(parameter: parameter)
        } else {
            throw ContainerError.noResolver
        }
    }

    /// Registers resolving closure for type `D`.
    public func register<D>(_ resolver: @escaping () -> D) {
        singletonTypeResolvers[key(D.self)] = resolver
        let optionalKey = key(Optional<D>.self)
        if singletonTypeResolvers[optionalKey] == nil && singletonTypeParametrizedResolvers[optionalKey] == nil {
            singletonTypeResolvers[optionalKey] = resolver
        }
    }

    /// Registers resolving closure with parameter for type `D`. `@Injected` annotation sends enclosing object as a parameter.
    public func register<D>(_ resolver: @escaping (_ parameter: Any) -> D) {
        singletonTypeParametrizedResolvers[key(D.self)] = resolver
        let optionalKey = key(Optional<D>.self)
        if singletonTypeResolvers[optionalKey] == nil && singletonTypeParametrizedResolvers[optionalKey] == nil {
            singletonTypeParametrizedResolvers[key(Optional<D>.self)] = resolver
        }
    }

    private func key<D>(_ type: D.Type) -> String {
        String(reflecting: type)
    }
}

public extension Container {
    /// Helper method that will crash if container has no resolver for specified type.
    func resolveOrDie<D>() -> D {
        do {
            guard let result: D = try resolve() else { fatalError("Couldn't resolve dependency \(D.self) (type mismatch)") }

            return result
        } catch {
            fatalError("Couldn't resolve dependency \(D.self) (\(error))")
        }
    }
}
