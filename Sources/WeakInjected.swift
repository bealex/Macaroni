//
//  WeakInjected.swift
//  Macaroni
//
//  Created by Anton Glezman on 20.01.2021.
//

@propertyWrapper
public struct WeakInjected<T> {
    
    private weak var value: AnyObject?
    
    public private(set) var wrappedValue: T? {
        get {
            value as? T
        }
        set {
            value = newValue as AnyObject
        }
    }

    public init(from scope: Scope = Scope.default) {
        self.wrappedValue = scope.container.resolveOrDie()
    }

    public init(from scope: Scope = Scope.default, _ initializer: (Container) -> T) {
        self.wrappedValue = initializer(scope.container)
    }
}
