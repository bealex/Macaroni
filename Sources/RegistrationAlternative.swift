//
// Alternative
// Macaroni
//
// Created by Alex Babaev on 13 August 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

import Foundation

public struct RegistrationAlternative: ExpressibleByStringLiteral {
    var name: String

    public init(_ value: StringLiteralType = UUID().uuidString) {
        name = value
    }

    public init(stringLiteral value: StringLiteralType = UUID().uuidString) {
        name = value
    }
}

public extension Container {
    func register<D>(_ resolver: @escaping () -> D) {
        register(alternative: Optional<String>.none, resolver)
    }

    func register<D>(alternative: RegistrationAlternative? = nil, _ resolver: @escaping () -> D) {
        register(alternative: alternative?.name, resolver)
    }

    func register<D>(_ resolver: @escaping (_ parameter: Any) -> D) {
        register(alternative: Optional<String>.none, resolver)
    }

    func register<D>(alternative: RegistrationAlternative? = nil, _ resolver: @escaping (_ parameter: Any) -> D) {
        register(alternative: alternative?.name, resolver)
    }

    func resolve<D>() throws -> D? {
        try resolve(alternative: Optional<String>.none)
    }

    func resolve<D>(alternative: RegistrationAlternative? = nil) throws -> D? {
        try resolve(alternative: alternative?.name)
    }

    func resolve<D>(parameter: Any) throws -> D? {
        try resolve(parameter: parameter, alternative: Optional<String>.none)
    }

    func resolve<D>(parameter: Any, alternative: RegistrationAlternative? = nil) throws -> D? {
        try resolve(parameter: parameter, alternative: alternative?.name)
    }
}
