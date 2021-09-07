//
// Container.FindPolicy
// Macaroni
//
// Created by Alex Babaev on 30 May 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

extension Container {
    public enum FindPolicy {
        public enum Finder {
            case direct(Container?)
            case indirect(() -> Container?)
        }

        case singleton(Container)
        case fromEnclosingObject(default: Container? = nil)
        case custom((_ enclosingObject: Any) -> Container)
    }

    public static var policy: FindPolicy?

    static func container<EnclosingType>(for instance: EnclosingType) -> Container {
        switch policy {
            case .singleton(let container)?:
                return container
            case .fromEnclosingObject(let defaultContainer)?:
                var foundContainer: Container?
                switch (instance as? Containerable)?.container {
                    case .direct(let container)?: foundContainer = container
                    case .indirect(let containerFinder)?: foundContainer = containerFinder()
                    case nil: break
                }
                if let container = foundContainer ?? defaultContainer {
                    return container
                } else {
                    Macaroni.logger.deathTrap("Can't find container for \(String(describing: instance.self))")
                }
            case .custom(let containerSelector)?:
                return containerSelector(instance)
            case nil:
                Macaroni.logger.deathTrap("Container selection policy (Macaroni.Container.policy) is not set")
        }
    }

    static func resolve<Value, EnclosingType>(for instance: EnclosingType, option: String? = nil) -> Value {
        let container = self.container(for: instance)
        let value: Value
        do {
            value = try container.resolve(parameter: instance, alternative: option)
        } catch {
            do {
                value = try container.resolve(alternative: option)
            } catch {
                let valueType = String(describing: Value.self)
                let enclosingType = String(describing: instance.self)
                Macaroni.logger.deathTrap("Can't find resolver for \"\(valueType)\" type in \"\(enclosingType)\" object")
            }
        }
        return value
    }
}
