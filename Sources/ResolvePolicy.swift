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
        case enclosingObjectWithContainer(defaultSingletonContainer: Container? = nil)
        case custom((_ enclosingObject: Any) -> Container)
    }

    public static var policy: Policy?

    static func container<EnclosingType>(for instance: EnclosingType) -> Container {
        switch policy {
            case .singleton(let container)?:
                return container
            case .enclosingObjectWithContainer(let defaultSingletonContainer)?:
                if let container = (instance as? WithContainer)?.container {
                    return container
                } else if let resolver = instance as? WithContainerResolver {
                    return resolver.container()
                } else if let container = defaultSingletonContainer {
                    return container
                } else {
                    let enclosingType = String(describing: instance.self)
                    Macaroni.handleError("Can't find container for \(enclosingType)")
                }
            case .custom(let containerSelector)?:
                return containerSelector(instance)
            case nil:
                Macaroni.handleError("Container selection policy (Macaroni.Container.policy) is not set")
        }
    }

    static func resolve<Value, EnclosingType>(for instance: EnclosingType) -> Value? {
        let container = self.container(for: instance)
        let value: Value?
        do {
            value = try container.resolve(parameter: instance)
        } catch {
            do {
                value = try container.resolve()
            } catch {
                let valueType = String(describing: Value.self)
                let enclosingType = String(describing: instance.self)
                Macaroni.handleError("Can't find resolver for \"\(valueType)\" type in \"\(enclosingType)\" object")
            }
        }
        return value
    }
}
