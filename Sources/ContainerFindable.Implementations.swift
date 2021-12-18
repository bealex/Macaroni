//
// ContainerLookup
// Macaroni
//
// Created by Alex Babaev on 18 December 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import Foundation

public class SingletonContainer: ContainerLookupPolicy {
    private let container: Container

    public init(_ container: Container) {
        self.container = container
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        container
    }
}

public protocol Containerable {
    var container: Container! { get }
}

public class EnclosingTypeContainer: ContainerLookupPolicy {
    private let defaultContainer: Container?

    public init(default: Container? = nil) {
        defaultContainer = `default`
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        (instance as? Containerable)?.container
    }
}
