//
// ContainerLookupPolicy
// Macaroni
//
// Created by Alex Babaev on 08 September 2022.
// Copyright © 2022 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

extension ContainerLookupPolicy {
    func resolve<Value, EnclosingType>(
        for instance: EnclosingType, option: String? = nil,
        file: StaticString = #fileID, function: String = #function, line: UInt = #line
    ) -> Value {
        guard let container = container(for: instance, file: file, function: function, line: line) else {
            let enclosingType = String(reflecting: instance.self)
            Macaroni.logger.die("Can't find container in \"\(enclosingType)\" object", file: file, function: function, line: line)
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
                Macaroni.logger.die("Can't find resolver for \"\(valueType)\" type in \"\(enclosingType)\" object")
            }
        }
        return value
    }
}
