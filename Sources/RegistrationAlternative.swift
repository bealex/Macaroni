//
// Alternative
// Macaroni
//
// Created by Alex Babaev on 13 August 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

/// If you need to add several objects of same type to the container, it will not be able to distinguish them.
/// To be able to do that, you can use `RegistrationAlternative`.
///
/// First, create a property of this type. The easiest way is to create it right inside `RegistrationAlternative` extension:
/// ```
/// extension RegistrationAlternative {
///     static let first: RegistrationAlternative = .init() // not recommended, logs will be hard to read.
///     static let second: RegistrationAlternative = "second"
/// }
/// ```
///
/// Then use this property during registration and during injection:
/// ```
/// container.register(alternative: .firstAlternative) { ... -> ... }
/// let ...: ... = container.resolve(alternative: .firstAlternative)
///
/// // or
///
/// @Injected(alternative: .second)
/// var instance: ...
/// ```
public struct RegistrationAlternative: ExpressibleByStringLiteral, Sendable {
    /// Name of the registration alternative. Is shown in logs.
    var name: String

    public init(_ value: StringLiteralType = UUID().uuidString) {
        name = value
    }

    public init(stringLiteral value: StringLiteralType = UUID().uuidString) {
        name = value
    }
}
