//
// ContainerBuilder
// Macaroni
//
// Created by Alex Babaev on 09.04.2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public protocol ContainerFactory {
    func container() -> Container
}

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
