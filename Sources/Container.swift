//
// DependencyInjection
// Macaroni
//
// Created by Alex Babaev on 30 May 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

/// Dependency injection container, that can create objects from their type.
public final class Container {
    private static var counter: Int = 1

    let name: String
    let parent: Container?

    public init(parent: Container? = nil, name: String? = nil) {
        self.parent = parent

        self.name = name ?? "UnnamedContainer.\(Container.counter)"
        Container.counter += 1
        Macaroni.logger.debug("\(self.name)\(self.parent == nil ? "" : " (parent: \(parent?.name ?? "???"))") created")
    }

    /// Resolvers that can create object by type.
    private var typeResolvers: [String: () -> Any] = [:]
    /// Resolvers that can create object, based on type and some arbitrary parameter.
    /// What is this parameter, depends on the usage.
    private var typeParametrizedResolvers: [String: (_ parameter: Any) -> Any] = [:]

    /// Returns true, if type is resolvable with the container or its parent.
    public func resolvable<D>(_ type: D.Type, option: String? = nil) -> Bool {
        let key = self.key(type, option: option)
        return typeParametrizedResolvers[key] != nil || typeResolvers[key] != nil || (parent?.resolvable(type) ?? false)
    }

    /// Returns instance of type `D`, if it is registered.
    public func resolve<D>(alternative: String? = nil) throws -> D {
        let key = self.key(D.self, option: alternative)
        if let resolver = typeResolvers[key] {
            return resolver() as! D
        } else if let parent = parent {
            return try parent.resolve(alternative: alternative)
        } else {
            throw MacaroniError.noResolver
        }
    }

    /// Returns instance of type `D`, if it is registered. Sends `parameter` to the resolver.
    /// For example, parameter can be a class name that encloses value that needs to be injected.
    public func resolve<D>(parameter: Any, alternative: String? = nil) throws -> D {
        let key = self.key(D.self, option: alternative)
        if let resolver = typeParametrizedResolvers[key] {
            return resolver(parameter) as! D
        } else if let parent = parent {
            return try parent.resolve(parameter: parameter, alternative: alternative)
        } else {
            throw MacaroniError.noResolver
        }
    }

    /// Registers resolving closure for type `D`.
    public func register<D>(alternative: String? = nil, _ resolver: @escaping () -> D) {
        typeResolvers[key(D.self, option: alternative)] = resolver
        let optionalKey = key(Optional<D>.self, option: alternative)
        if typeResolvers[optionalKey] == nil && typeParametrizedResolvers[optionalKey] == nil {
            typeResolvers[optionalKey] = resolver
        }
        Macaroni.logger.debug("\(name) is registering resolver for \(String(describing: D.self))\(alternative.map { "/\($0)" } ?? "")")
    }

    /// Registers resolving closure with parameter for type `D`. `@Injected` annotation sends enclosing object as a parameter.
    public func register<D>(alternative: String? = nil, _ resolver: @escaping (_ parameter: Any) -> D) {
        typeParametrizedResolvers[key(D.self, option: alternative)] = resolver
        let optionalKey = key(Optional<D>.self, option: alternative)
        if typeResolvers[optionalKey] == nil && typeParametrizedResolvers[optionalKey] == nil {
            typeParametrizedResolvers[key(Optional<D>.self, option: alternative)] = resolver
        }
        Macaroni.logger.debug("\(name) is registering parametrized resolver for \(String(describing: D.self))\(alternative.map { "/\($0)" } ?? "")")
    }

    /// Removes all resolvers.
    public func cleanup() {
        typeResolvers = [:]
        typeParametrizedResolvers = [:]
        Macaroni.logger.debug("\(name) cleared")
    }

    private func key<D>(_ type: D.Type, option: String?) -> String {
        "\(String(reflecting: type))\(option.map { ".\($0)" } ?? "")"
    }
}

extension Container {
    public struct Resolver<Value> {
        public let container: Container
        public let alternative: String?

        public init(container: Container, alternative: String? = nil) {
            self.container = container
            self.alternative = alternative
        }

        public func resolve() throws -> Value {
            try container.resolve(alternative: alternative)
        }

        public func resolvable(_ type: Value.Type, option: String? = nil) -> Bool {
            container.resolvable(Value.self)
        }
    }

    /// For using with @Injected wrapper in functions, like this: `foo($parameter: container.resolved)`
    public func resolved<D>(alternative: String? = nil) -> Resolver<D> { .init(container: self, alternative: alternative) }
}
