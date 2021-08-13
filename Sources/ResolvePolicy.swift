//
// ResolvePolicy
// Macaroni
//
// Created by Alex Babaev on 30 May 2020.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

extension Container {
    public enum Policy {
        case singleton(Container)
        case fromEnclosingObject(default: Container? = nil)
        case custom((_ enclosingObject: Any) -> Container)
    }

    public static var policy: Policy?

    static func container<EnclosingType>(for instance: EnclosingType) -> Container {
        switch policy {
            case .singleton(let container)?:
                return container
            case .fromEnclosingObject(let defaultSingletonContainer)?:
                if let container = (instance as? WithContainer)?.container {
                    return container
                } else if let resolver = instance as? WithContainerResolver {
                    return resolver.container()
                } else if let container = defaultSingletonContainer {
                    return container
                } else {
                    Macaroni.logger.errorAndDie("Can't find container for \(String(describing: instance.self))")
                }
            case .custom(let containerSelector)?:
                return containerSelector(instance)
            case nil:
                Macaroni.logger.errorAndDie("Container selection policy (Macaroni.Container.policy) is not set")
        }
    }

    static func resolve<Value, EnclosingType>(for instance: EnclosingType, option: String? = nil) -> Value? {
        let container = self.container(for: instance)
        let value: Value?
        do {
            value = try container.resolve(parameter: instance, alternative: option)
        } catch {
            do {
                value = try container.resolve(alternative: option)
            } catch {
                let valueType = String(describing: Value.self)
                let enclosingType = String(describing: instance.self)
                Macaroni.logger.errorAndDie("Can't find resolver for \"\(valueType)\" type in \"\(enclosingType)\" object")
            }
        }
        return value
    }
}
