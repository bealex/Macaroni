//
// ContainerFindable
// Macaroni
//
// Created by Alex Babaev on 30 May 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

public extension Container {
    /// This property is being used to find out container search policy.
    /// Please set it up before any @Injected (and others) property wrappers are used.
    static nonisolated(unsafe) var lookupPolicy: ContainerLookupPolicy!
}

/// ContainerLookupPolicy is a protocol that can control, how container for an injection is being looked up, if property wrapper is used.
/// For now the only parameter that you can use for that is an instance of a reference type, where injection is happening.
public protocol ContainerLookupPolicy: AnyObject {
    /// Implement this to be able to look up for the container. For examples see [ContainerFindable.Implementations.swift]
    /// (ContainerFindable.Implementations.swift)
    /// - Parameters:
    ///   - instance: instance of a reference type injection will happen.
    ///   - file: call originating file, used for logging
    ///   - function: call originating function, used for logging
    ///   - line: call originating line, used for logging
    /// - Returns: Container that will be used for the injection (if any).
    func container<EnclosingType>(for instance: EnclosingType, file: StaticString, function: String, line: UInt) -> Container?
}
