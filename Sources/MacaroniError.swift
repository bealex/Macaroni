//
// MacaroniError
// Macaroni
//
// Created by Alex Babaev on 18 December 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

public enum MacaroniError: Error {
    /// No resolvers was found for the type.
    case noResolver
    /// Container.policy is not initialized.
    case noContainerLookupPolicy
    /// Object does not implement Containerable protocol.
    case notContainerable(enclosingTypeName: String)
    /// Containerable object does not contain Container.
    case noContainerFound(forEnclosingType: String)
}

