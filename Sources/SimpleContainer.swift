//
// SimpleContainer
// Macaroni
//
// Created by Alex Babaev on 21 June 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public class SimpleContainer: Container {
    private let parent: Container?

    public init(parentContainer: Container? = nil) {
        parent = parentContainer
    }

    /**
        Resolvers that can create object by type.
     */
    private var typeResolvers: [String: () -> Any] = [:]
    /**
        Resolvers that can create object, based on type and some arbitrary parameter.
        What is this parameter, depends on the usage.
     */
    private var typeParametrizedResolvers: [String: (_ parameter: Any) -> Any] = [:]

    public func register<D>(_ resolver: @escaping () -> D) {
        typeResolvers[key(D.self)] = resolver
        typeResolvers[key(Optional<D>.self)] = resolver
    }

    public func register<D>(_ resolver: @escaping (_: Any) -> D) {
        typeParametrizedResolvers[key(D.self)] = resolver
        typeParametrizedResolvers[key(Optional<D>.self)] = resolver
    }

    public func resolve<D>() throws -> D? {
        if let resolver = typeResolvers[key(D.self)] {
            return try resolver() as? D ?? parent?.resolve()
        } else {
            throw ContainerError.noResolver
        }
    }

    public func resolve<D>(parameter: Any) throws -> D? {
        if let resolver = typeParametrizedResolvers[key(D.self)] {
            return try resolver(parameter) as? D ?? parent?.resolve(parameter: parameter)
        } else {
            throw ContainerError.noResolver
        }
    }

    private func key<D>(_ type: D.Type) -> String {
        String(reflecting: type)
    }
}
