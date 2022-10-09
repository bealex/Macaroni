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

/// Dependency injection container, that can create objects from their type.
public final class Container {
    let name: String
    let parent: Container?

    private static var counter: Int = 1

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

    private func key<D>(_ type: D.Type, alternative: String?) -> String {
        "\(String(reflecting: type))\(alternative.map { ".\($0)" } ?? "")"
    }

    /// Returns true, if type is resolvable with the container or its parent.
    public func isResolvable<D>(_ type: D.Type, alternative: String? = nil) -> Bool {
        let key = self.key(type, alternative: alternative)
        return typeParametrizedResolvers[key] != nil || typeResolvers[key] != nil || (parent?.isResolvable(type) ?? false)
    }

    /// Registers resolving closure for type `D`.
    public func register<D>(alternative: String? = nil, _ resolver: @escaping () -> D) {
        let nonOptionalKey = key(D.self, alternative: alternative)
        typeResolvers[nonOptionalKey] = resolver
        Macaroni.logger.debug("\(name) is registering resolver for \(String(describing: D.self))\(alternative.map { "/\($0)" } ?? "")")

        let optionalKey = key(Optional<D>.self, alternative: alternative)
        if typeResolvers[optionalKey] == nil && typeParametrizedResolvers[optionalKey] == nil {
            typeResolvers[optionalKey] = resolver
            Macaroni.logger.debug("\(name) is registering resolver for \(String(describing: Optional<D>.self))\(alternative.map { "/\($0)" } ?? "")")
        }
    }

    /// Registers resolving closure with parameter for type `D`. `@Injected` annotation sends enclosing object as a parameter.
    public func register<D>(alternative: String? = nil, _ resolver: @escaping (_ parameter: Any) -> D) {
        let nonOptionalKey = key(D.self, alternative: alternative)
        typeParametrizedResolvers[nonOptionalKey] = resolver
        Macaroni.logger.debug("\(name) is registering parametrized resolver for \(String(describing: D.self))\(alternative.map { "/\($0)" } ?? "")")

        let optionalKey = key(Optional<D>.self, alternative: alternative)
        if typeResolvers[optionalKey] == nil && typeParametrizedResolvers[optionalKey] == nil {
            typeParametrizedResolvers[optionalKey] = resolver
            Macaroni.logger.debug("\(name) is registering parametrized resolver for \(String(describing: Optional<D>.self))\(alternative.map { "/\($0)" } ?? "")")
        }
    }

    /// Returns instance of type `D`, if it is registered.
    public func resolve<D>(alternative: String? = nil) throws -> D {
        let key = self.key(D.self, alternative: alternative)
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
        let key = self.key(D.self, alternative: alternative)
        if let resolver = typeParametrizedResolvers[key] {
            return resolver(parameter) as! D
        } else if let parent = parent {
            return try parent.resolve(parameter: parameter, alternative: alternative)
        } else {
            throw MacaroniError.noResolver
        }
    }

    /// Removes all resolvers.
    public func cleanup() {
        typeResolvers = [:]
        typeParametrizedResolvers = [:]
        Macaroni.logger.debug("\(name) cleared")
    }
}

public extension Container {
    struct Resolver<Value> {
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
            container.isResolvable(Value.self)
        }
    }

    /// For using with @Injected wrapper in functions, like this: `foo($parameter: container.resolved)`
    func resolved<D>(alternative: String? = nil) -> Resolver<D> { .init(container: self, alternative: alternative) }
}

public extension Container {
    func register<D>(_ resolver: @escaping () -> D) {
        register(alternative: Optional<String>.none, resolver)
    }

    func register<D>(alternative: RegistrationAlternative? = nil, _ resolver: @escaping () -> D) {
        register(alternative: alternative?.name, resolver)
    }

    func register<D>(_ resolver: @escaping (_ parameter: Any) -> D) {
        register(alternative: Optional<String>.none, resolver)
    }

    func register<D>(alternative: RegistrationAlternative? = nil, _ resolver: @escaping (_ parameter: Any) -> D) {
        register(alternative: alternative?.name, resolver)
    }

    func resolve<D>() throws -> D? {
        try resolve(alternative: Optional<String>.none)
    }

    func resolve<D>(alternative: RegistrationAlternative? = nil) throws -> D? {
        try resolve(alternative: alternative?.name)
    }

    func resolve<D>(parameter: Any) throws -> D? {
        try resolve(parameter: parameter, alternative: Optional<String>.none)
    }

    func resolve<D>(parameter: Any, alternative: RegistrationAlternative? = nil) throws -> D? {
        try resolve(parameter: parameter, alternative: alternative?.name)
    }
}
