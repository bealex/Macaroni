//
// SingletonContainerFactory
// Macaroni
//
// Created by Alex Babaev on 21 June 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

open class SingletonContainerFactory: ContainerFactory {
    public init() {
    }

    private var builtContainer: Container?
    public func container() -> Container {
        if let container = builtContainer {
            return container
        } else {
            let result = build()
            builtContainer = result
            return result
        }
    }

    open func build() -> Container {
        fatalError("Please implement")
    }
}
