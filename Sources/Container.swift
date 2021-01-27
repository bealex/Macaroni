//
// DependencyInjection
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public protocol Container {
    func resolve<D>() -> D?
    func resolve<D>(parameter: Any) -> D?
}

public extension Container {
    func resolveOrDie<D>() -> D {
        guard let result: D = resolve() else { fatalError("Couldn't resolve dependency \(D.self)") }

        return result
    }
}
