//
// ContainerFindable
// Macaroni
//
// Created by Alex Babaev on 30 May 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

public protocol ContainerFindable {
    func container<EnclosingType>(for instance: EnclosingType, file: String, function: String, line: UInt) -> Container?
}

public extension Container {
    static var policy: ContainerFindable = UninitializedContainer()
}

extension ContainerFindable {
    func resolve<Value, EnclosingType>(
        for instance: EnclosingType, option: String? = nil,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Value {
        guard let container = container(for: instance, file: file, function: function, line: line) else {
            let enclosingType = String(reflecting: instance.self)
            Macaroni.logger.deathTrap("Can't find container in \"\(enclosingType)\" object")
        }

        let value: Value
        do {
            value = try container.resolve(parameter: instance, alternative: option)
        } catch {
            do {
                value = try container.resolve(alternative: option)
            } catch {
                let valueType = String(reflecting: Value.self)
                let enclosingType = String(reflecting: instance.self)
                Macaroni.logger.deathTrap("Can't find resolver for \"\(valueType)\" type in \"\(enclosingType)\" object")
            }
        }
        return value
    }
}
