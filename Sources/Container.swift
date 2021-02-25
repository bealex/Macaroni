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
public protocol Container {
    /// Returns instance of type `D`, if it is registered.
    func resolve<D>() throws -> D?
    /// Returns instance of type `D`, if it is registered. Sends `parameter` to the resolver.
    /// For example, parameter can be a class name that encloses value that needs to be injected.
    func resolve<D>(parameter: Any) throws -> D?
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
