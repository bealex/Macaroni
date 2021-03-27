//
// WithContainer
// Macaroni
//
// Created by Alex Babaev on 26 March 2021.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

import Foundation

public protocol WithContainer {
    var container: Container! { get }
}

public protocol WithContainerResolver {
    var container: () -> Container { get }
}
