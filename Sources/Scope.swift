//
// Scopes
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

open class Scope {
    public static var `default`: Scope!

    private let factory: ContainerFactory
    public var container: Container { factory.container() }

    public init(factory: ContainerFactory) {
        self.factory = factory
    }
}
