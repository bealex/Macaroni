//
// Macaroni
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
//

public enum Macaroni {
    /// Service method. You can override it if you want some specific error handling.
    static var handleError: (String) -> Never = { string in
        fatalError(string)
    }
}
