//
// DependencyInjection
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public enum ContainerError: Error {
    case noResolver
}

public protocol Container {
    func resolve<D>() throws -> D?
    func resolve<D>(parameter: Any) throws -> D?
}

public extension Container {
    func resolveOrDie<D>() -> D {
        do {
            guard let result: D = try resolve() else { fatalError("Couldn't resolve dependency \(D.self) (type mismatch)") }

            return result
        } catch {
            fatalError("Couldn't resolve dependency \(D.self) (\(error))")
        }
    }
}
