//
// ContainerSelector
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

open class ContainerSelector {
    public static let defaultContainer: Container = Container()
    public static var `for`: (_ enclosedObject: Any) -> Container  = { _ in defaultContainer }
}
