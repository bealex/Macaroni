# Macaroni
Swift Dependency Injection Framework "Macaroni".

#### Main reason to exist

When I start my projects, I need some kind of DI. When [property wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md) were introduced, it was obvious that this feature can be used for DI framework. So here it is.

Macaroni v.2 uses a hack from this article https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/ to be able to access `self` of the enclosing object. There is a limitation because of that: `@Injected` can be used _only in classes_, because properties are being lazy initialized when accessed first time.

#### Migration
 - [from v 1.x to v 2.x](Documentation/Migration1-2.md)

## Installation

Please use [Swift Package Manager](https://swift.org/package-manager/). Repository address: `git@github.com:bealex/Macaroni.git`. Name: `Macaroni`.

## Simple example

First let's import Macaroni and prepare our protocol and implementation that we want to inject.

```swift
import Macaroni

protocol MyService {}
class MyServiceImplementation: MyService {}
```

Now let's register the service inside a dependency injection container (`Macaroni.Container`). Think of Container as a box that holds all objects for injection. We will use simple, [service locator](https://en.wikipedia.org/wiki/Service_locator_pattern) DI policy (other policies are described later).

```swift
func configure() {
    let container = Container()

    // This variant will create singleton resolver:
    let myService = MyServiceImplementation()
    container.register { myService }
    
    // And this object will be created every time during injection:
    container.register { MyServiceImplementation() }
    
    Container.policy = .singleton(container)
}
```

Please note that type of myService is inferred. This is why it will be able to inject it as `MyServiceImplementation`, but not `MyService`. To enable the latter, you should specify it either at declaration:

```swift
let myService: MyService = MyServiceImplementation()
```

Or during the registration:

```swift
container.register { () -> MyService in myService }
```

Now we can inject things!

```swift
class MyController {
    @Injected
    var myService: MyService
}
``` 

Please note that injection will happen lazily, not during `MyController` initialization but when `myService` is first accessed.

## Using information about enclosing object (parametrized injection)

If you need to use object that contains injected property, you can get it inside registration closure like this:

```swift
container.register { enclosingObject -> String in String(describing: enclosing) }
```

> Please note that there will be enclosed object only for `@Injected` and `@InjectedWeakly` Macaroni implementations. If you use Container in some custom environment, you are responsible for what is put there and how to use it. Macaroni property wrappers `@Injected` and `@InjectedWeakly` are using it only this way. 

## `@Injected` resolve procedure

> You can see all logic in `ResolvePolicy.swift`.

If there is no value stored for the field, then it is created:
 - First, it looks for the parametrized resolver
 - Next, non-parametrized resolver
 - If nothing found, fatal error happens. You can override this behavior with the property: `Macaroni.handleError`

If you will simultaneously register parametrized type resolver with non-parametrized one, parametrized will take precedence.

## DI Policies

There are three policies of container selection for properties of specific enclosing object:
 - service locator style. It is called `.singleton`, and can be set up like this: `Container.policy = .singleton(myContainer)`.
 - enclosing object based. This policy implies, that every enclosing object implements `WithContainer` protocol and contains its own `Container` because of that. You can set it up like this: `Container.policy = .enclosingObjectWithContainer` or if you want to use default singleton container for all objects that do not implement `WithContainer`, you can set default one: `Container.policy = .enclosingObjectWithContainer(defaultSingletonContainer: myDefaultContainer)`
- custom. If you want to control container selection yourself and no other options help you, you can set it like this: `Container.policy = .custom { enclosingObject in /* your container selection policy */ }`

## Weak injection

When using property wrappers, you can't use `weak` (or `lazy` or `unowned`). If you need that, you can use `@InjecteadWeakly` instead of `@Injected`. Here is an example:

```swift
private protocol MyService: AnyObject {}
private class MyServiceImplementation: MyService {}

private class MyController {
    @InjectedWeakly
    var myService: MyService?
}

// Please note that registration should not strongly capture an object. You should do something like this
let service: MyService = MyServiceImplementation()
let container = Container()
container.register { [weak service] in service }
Container.policy = .singleton(container)
```

## Per Module Injection

If your application uses several modules and each module needs its own `Container`, you can use this option:

```swift
// Common code:
protocol ModuleDI: WithContainer {}

// Using this policy for each object to decide what container to use.  
Container.policy = .enclosingObjectWithContainer()

// Module specific code:
// In each module create a container, and fill it with needed resolvers.
private var moduleContainer: Container!
// Extension is internal. This way each module can have its own 
extension ModuleDI {
    var container: Container! { moduleContainer }
}

// And we can "inject" container like this.
class MyCoordinator: ..., ModuleDI, ... {
    ...
}
```

## Multithreading support

Macaroni does not do anything about multithreading. Please handle it yourself if needed.
