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
        self.parent = parentContainer
    }

    private var typeResolvers: [String: () -> Any] = [:]

    public func register<D>(_ resolver: @escaping () -> D) {
        typeResolvers[key(D.self)] = resolver
        typeResolvers[key(Optional<D>.self)] = resolver
    }

    public func resolve<D>() -> D? {
        print("... \(key(D.self))")
        return typeResolvers[key(D.self)]?() as? D ?? parent?.resolve()
    }

    private func key<D>(_ type: D.Type) -> String {
        String(reflecting: type)
    }
}
