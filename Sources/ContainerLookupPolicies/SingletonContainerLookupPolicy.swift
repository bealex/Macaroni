//
// SingletonContainerLookupPolicy
// Macaroni
//
// Created by Alex Babaev on 08 September 2022.
// Copyright © 2022 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

public extension ContainerLookupPolicy where Self == SingletonContainer {
    static func singleton(_ container: Container) -> ContainerLookupPolicy {
        SingletonContainer(container)
    }
}

public class SingletonContainer: ContainerLookupPolicy {
    private let container: Container

    public init(_ container: Container) {
        self.container = container
    }

    public func container<EnclosingType>(
        for instance: EnclosingType,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Container? {
        container
    }
}

