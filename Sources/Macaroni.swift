//
// Macaroni
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public enum Macaroni {
    /// Service method. You can override it if you want some specific error handling.
    static var handleError: (String) -> Never = { string in
        fatalError(string)
    }
}
