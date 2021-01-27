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

    /// Resolvers that can create object by type.
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

    public func resolve<D>() -> D? {
        typeResolvers[key(D.self)]?() as? D ?? parent?.resolve()
    }

    public func resolve<D>(parameter: Any) -> D? {
        typeParametrizedResolvers[key(D.self)]?(parameter) as? D ?? parent?.resolve()
    }

    private func key<D>(_ type: D.Type) -> String {
        String(reflecting: type)
    }
}
