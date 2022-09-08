//
// ContainerableLookupPolicy
// Macaroni
//
// Created by Alex Babaev on 08 September 2022.
// Copyright © 2022 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

public protocol Containerable {
    var container: Container! { get }
}

public extension ContainerLookupPolicy where Self == EnclosingTypeContainer {
    static func enclosingType(default: Container? = nil) -> ContainerLookupPolicy {
        EnclosingTypeContainer(default: `default`)
    }
}

public class EnclosingTypeContainer: ContainerLookupPolicy {
    private let defaultContainer: Container?

    public init(default: Container? = nil) {
        defaultContainer = `default`
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        (instance as? Containerable)?.container
    }
}
