# Macaroni
It's a Swift Dependency Injection Framework that is called “Macaroni”. 
Cut [Spaghetti Code](https://en.wikipedia.org/wiki/Spaghetti_code) into pieces! :–)

#### Main reason to exist

When I start my projects, I need some kind of DI. 
It's obvious that [property wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md) 
can be used for DI framework. Here it is.

Macaroni uses a hack from this article https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/ 
to be able to access `self` of the enclosing object. There is a limitation because of that: `@Injected` can be used _only in reference types_, 
because properties are being lazy initialized when accessed first time, thus changing the container
(which is problematic to do with value types).

#### Migration

Please look at [UPDATE.md](UPDATES.md) to find out about migrations.

## Installation

Please use [Swift Package Manager](https://swift.org/package-manager/). 
Repository address: `git@github.com:bealex/Macaroni.git` or `https://github.com/bealex/Macaroni.git`. 
Name of the package is `Macaroni`.

### Current version

Current version is v4.x
    
## 30-second tutorial

```swift
// Create the container.
let container = Container()
// Set it as a singleton for the simplest service-locator style resolution.
Container.policy = .singleton(container)

// Add service implementations into the container.
let myService = MyServiceImplementation()
container.register { () -> MyService in myService }

// Use it in code.
let myService: MyService = container.resolve()

// Or use it with property wrapper.
class MyClass {
   @Injected
   var service: MyService
}
```

## Example

First let's import Macaroni and prepare our protocol and implementation that we want to inject.

```swift
import Macaroni

protocol MyService {}
class MyServiceImplementation: MyService {}
```

Macaroni should know where container is placed, to get objects for injection. You can think of _container_ as a box 
that holds all the objects. The knowledge of where container is placed is defined by `Container.lookupPolicy`.
Let's use simple [service locator](https://en.wikipedia.org/wiki/Service_locator_pattern) policy, that uses
a `singleton` object to hold all the objects that can be injected.

```swift
let container = Container()
Container.policy = .singleton(container)
```

To register something inside a container, we register a _resolver_ there. Resolver is a closure that 
returns instance of a specific type. It can return same instance all the time, can create it each time it is accessed. You choose.
For now let's register the resolver, that returns same instance every time it is used.

```swift
let myService = MyServiceImplementation()
container.register { myService }
```

And then we can inject this value like this:

```swift
class MyClass {
    @Injected
    var myService: MyServiceImplementation
}
```

Usually we need to be able to use it with the protocol like this: `var myService: MyService`, not with the implementation 
type (`var myService: MyServiceImplementation`). For that we need to tell `Container`, that if it is being asked of `MyService`, 
it should inject this specific object. It can be done using one of two options:

```swift
// 1. 
// Now myService is of type `MyService` and registration will be
// typed as `() -> MyService` instead of `() -> MyServiceImplementation`
let myService: MyService /* <- Magic happens here */ = MyServiceImplementation()
container.register { myService }

// 2.
// or like this (I prefer this option):
let myService = MyServiceImplementation()
container.register { () -> MyService /* <- Magic happens here */ in myService }
```

> Please note that injection is happening lazily, not during `MyController` initialization but when `myService` is first accessed.
 
In the code above, implementation is being created right away. If you want to lazily create objects that 
should be injected, you can use a wrapper like this:

```swift
class LazilyInitialized<Type> {
   lazy var value: Type = { resolver() }()

   private let resolver: () -> Type

   init(resolver: @escaping () -> Type) {
      self.resolver = resolver
   }
}

let willBeInstantiatedOnFirstAccess = LazilyInitialized { MyServiceImplementation() }
container.register { () -> MyService in willBeInstantiatedOnFirstAccess.value }
```

## `Injected` options

#### Class property injection

```swift
// 1. 
// Lazy injection from the container that is captured on initialization, determined by `Container.policy`:
@Injected
var property: Type

// 2.
// Lazy injection from the container that is captured on initialization (you specify it):
@Injected(.capturingContainerOnInit(from: container))
var property: Type

// 3. 
// Lazy capturing of the container and resolving:
@Injected(.lazily)
var property: Type

// 4.
// Eager resolving, during the initialization, from the container from `Container.policy`:
@Injected(.resolvingOnInit())
var property: Type

// 5.
// Eager resolving, during the initialization, from the specified container:
@Injected(.resolvingOnInit(from: container))
var property: Type
```

> Please note that parametrized injection works only when object is being resolved lazily. 
> Eager injection can only resolve objects by type (and alternative if it is provided).
> 
> Also lazy injection can't be used in `structs`, because it needs to modify object after the resolve. 
        
#### Resolving several objects with the same type

```swift
//    - create alternative identifier. Strings must be different for different types.
extension RegistrationAlternative {
    static let another: RegistrationAlternative = "another"
}
//    - registration
container.register(alternative: .another) { () -> MyService in anotherInstance }
//    - injection
@Injected(alternative: .another)
var myServiceAlternative: MyService 
```

#### Function parameter injection

Starting from Swift 5.5 we can use property wrappers for function parameters too. Here is the function declaration:

```swift
func foo(@Injected service: MyService) { /* Use service here */ }
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
container.register { enclosing -> String in String(describing: enclosing) }
```

> This resolver will be available for lazy injections only.

## Weak injection

When using property wrappers, you can't use `weak` (or `lazy` or `unowned`). If you need that, you can use `@InjecteadWeakly`.

```swift
@InjectedWeakly
var myService: MyService?
```

## Container lookup Policies

There are three policies of container selection for properties of specific enclosing object:
 - service locator style. It is called `singleton`, and can be set up like this: `Container.policy = .singleton(myContainer)`.
 - enclosing object based. This policy implies, that every enclosing type implements `Containerable`
   protocol that defines `Container` for the object. You can set it up with `.enclosingType(default:)`.
 - custom. If you want to control container finding yourself and no other option suits you, you can implement `ContainerLookupPolicy` yourself.

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

By default, Macaroni will print simple events (container creation, resolver registering, injections) to the console. If you don't need that
(or need to alter logs in some way), please set `Macaroni.Logger` to your implementation of `MacaroniLogger`:

```swift
class MyMacaroniLogger: MacaroniLogger {
    func log(/* Parameters */) { /* Logging code */ }
    func die() -> Never { /* Log and crash */ }
}

Macaroni.logger = MyMacaroniLogger()
```

Use this code to disable logging completely:

```swift
Macaroni.logger = DisabledMacaroniLogger()
```

## License

License: MIT, https://github.com/bealex/Macaroni/blob/main/LICENSE
