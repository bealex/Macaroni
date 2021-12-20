# Macaroni
It's a Swift Dependency Injection Framework that is called “Macaroni”. 
Cut [Spaghetti Code](https://en.wikipedia.org/wiki/Spaghetti_code) into pieces! :–)

#### Main reason to exist

When I start my projects, I need some kind of DI. 
It's obvious that [property wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md) 
can be used for DI framework. Here it is.

Macaroni uses a hack from this article https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/ 
to be able to access `self` of the enclosing object. There is a limitation because of that: `@Injected` can be used _only in classes_, 
because properties are being lazy initialized when accessed first time, thus changing the object it is contained in
(and it is not easy to do with value types).

#### Migration

Please look at [UPDATE.md](UPDATES.md) to find out about migrations.

## Installation

Please use [Swift Package Manager](https://swift.org/package-manager/). 
Repository address: `git@github.com:bealex/Macaroni.git` or `https://github.com/bealex/Macaroni.git`. 
Name of the package is `Macaroni`.

Current version is v2.x
    
## 30-second tutorial

```swift
// Create container
let container = Container()
// Set it as a singleton
Container.policy = .singleton(container)
// Add service implementations into the container
let myService = MyServiceImplementation()
container.register { () -> MyService in myService }

// Use it in classes
class MyClass {
   @Injected var service: MyService
}
```

## Example

First let's import Macaroni and prepare our protocol and implementation that we want to inject.

```swift
import Macaroni

protocol MyService {}
class MyServiceImplementation: MyService {}
```

Macaroni should know where container is placed, to get objects out of it and inject them. You can think of _container_ as a box 
that holds all objects for injection. This knowledge of where container is placed is defined by `Container.FindPolicy` enum.
Let's use simple [service locator](https://en.wikipedia.org/wiki/Service_locator_pattern) container finding policy, that uses
a `singleton` object to hold all the objects that can be injected.

```swift
let container = Container()
Container.policy = .singleton(container)
```

To register the service inside a dependency injection container, we register a _resolver_ there. Resolver is a closure that 
returns instance of a specific type. It can return same instance all the time, can create it each time it is accessed. You choose.
For now let's register the resolver, that returns same instance every time it is used.

```swift
let myService = MyServiceImplementation()
container.register { myService }
```

And then, later, in some `class` we can inject this value like this:

```swift
@Injected var myService: MyServiceImplementation
```

To be able to use it with the protocol like this:

```swift
@Injected var myService: MyService
```

we need to tell `Container`, that if it is being asked of `MyService`, it should inject this specific implementation. 
It can be done like this:

```swift
let myService: MyService = MyServiceImplementation()
// Now myService is of type `MyService` and registration will be
// typed as `() -> MyService` instead of `() -> MyServiceImplementation`
container.register { myService }
```

or like this:

```swift
let myService = MyServiceImplementation()
container.register { () -> MyService in myService }
```

> Please note that injection is happening lazily, not during `MyController` initialization but when `myService` is first accessed.

## `Injected` options

#### Class property injection

Lazy injection from the container, determined by `Container.policy`:

```swift
@Injected var property: Type
```

Lazy injection of an alternative object of the same type from the container, determined by `Container.policy`:

```swift
// create alternative identifier. Strings must be different for different types.
extension RegistrationAlternative {
    static let another: RegistrationAlternative = "another"
}
// registration
container.register(alternative: .another) { () -> MyService in anotherInstance }
// injection
@Injected(alternative: .another) var myServiceAlternative: MyService 
```

Eager injection from specific container:

> Please note that parametrized injection is not working in this case.

```swift
@Injected(container: container) var service: MyService
```

#### Function parameter injection

Starting from Swift 5.5 we can use property wrappers for function parameters too. Here is the function declaration:

```swift
func foo(@Injected service: MyService) { ... }
```

And its call using default instance:

```swift
foo($service: container.resolved())
```

Or alternative instance

```swift
foo($service: container.resolved(alternative: .another))
```

#### Using information about enclosing object (parametrized injection)

If you need to use object that contains the injected property, you can get from inside registration closure like this:

```swift
container.register { enclosingObject -> String in String(describing: enclosing) }
```

> This resolver will be available for lazy injections only.

## Weak injection

When using property wrappers, you can't use `weak` (or `lazy` or `unowned`). If you need that, you can use `@InjecteadWeakly`.

```swift
@InjectedWeakly var myService: MyService?
```

## Eager (init-time) injection

Using `container` parameters shows that initialization can happen right away.

```swift
@Injected(container: Container) var myService: MyService
```

## Container lookup Policies

There are three policies of container selection for properties of specific enclosing object:
 - service locator style. It is called `singleton`, and can be set up like this: `Container.policy = .singleton(myContainer)`.
 - enclosing object based. This policy implies, that every enclosing type implements `Containerable`
   protocol that defines `Container` for the object. You can set it up with `.enclosingType(default:)`.
 - custom. If you want to control container finding yourself and no other options suit you, you can implement `ContainerLookupPolicy` yourself.

## Per Module Injection

If your application uses several modules and each module needs its own `Container`, you can use this option:

Write this somewhere in the common module:

```swift
protocol ModuleDI: Containerable {}
Container.policy = EnclosingTypeContainer()
```

And this in each module:

```swift
private var moduleContainer: Container!
extension ModuleDI {
    var container: Container! { moduleContainer } // now each module does have its own container
}

class MyClass: ModuleDI {
    @Inject var service: MyService // will be injected from the `moduleContainer`
}
```

## Multithreading support

Macaroni does not do anything about multithreading. Please handle it yourself if needed.

### Logging

By default, Macaroni will log simple events: containers creation and resolvers registering. If you don't need that
(or need to alter logs in some way), please set `Macaroni.Logger` to your implementation of `MacaroniLogger`:

```swift
class MyMacaroniLogger: MacaroniLogger {
    func log(...) { ... }
    func die() -> Never { ... }
}

Macaroni.logger = MyMacaroniLogger()
```

Use this code to disable logging completely:

```swift
Macaroni.logger = DisabledMacaroniLogger()
```

## License

License: MIT, https://github.com/bealex/Macaroni/blob/main/LICENSE

