# Macaroni
Swift Dependency Injection Framework "Macaroni".

#### Main reason to exist

When I start my projects, I need some kind of DI. When [property wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md) were introduced, it was obvious that this feature can be used for DI framework. So here it is.

Macaroni v.2 uses a hack from this article https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/ to be able to access `self` of the enclosing object. There is a limitation because of that: @Injected can be used _only in classes_, because properties are being lazy initialized when accessed first time.

## Simple example

First let's import Macaroni and prepare our protocol.

```swift
import Macaroni

protocol MyService {}
class MyServiceImplementation: MyService {}
```

Now let's register the service inside a DI container (`Macaroni.Container`). Think of Container as a box that holds all objects for injection.

```swift
func configure() {
    let container = ContainerSelector.defaultContainer
    
    // This variant will create singleton resolver.
    let myService = MyServiceImplementation()
    container.register { myService }
    
    // If you want object to be created every time, you can use it like this:
    container.register { MyServiceImplementation() }
}
```

Please note that type of myService is inferred. This is why it will be able to inject it as `MyServiceImplementation`, but not `MyService`. To enable the latter, you should specify it either at declaration

```swift
let myService: MyService = MyServiceImplementation()
```

Or diring the registration:

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

## Using information about enclosing object

If you need to use object that contains injected property, you can get it inside registration closure like this:

```swift
container.register { (enclosing: Any) -> String in String(describing: enclosing) }
```

## `@Injected` resolve procedure
                                             
If there is no value stored for the field, then it is created:
 - First, it looks for the parametrized resolver
 - Next, non-parametrized resolver
 - If nothing found, fatal error happens. You can override this behavior with the property: `Macaroni.handleError`
   
If you will simultaneously register parametrized type resolver with non-parametrized one, parametrized will take precedence. You can see all logic in `struct Injected`.

## Several containers

You can use several containers inside your app. Which container will be used during the injection is defined by `ContainerSelector.for(_ enclosedObject: Any)` closure. By default it uses `defaultContainer` for all injections.

For example, you can use serviceContainer for all your service layer objects, uiContainer for different UI classes and `defaultContainer` for everything else. How to implement this is totally up to you. I use marker protocols for this:

```swift
// Define marker protocols:
protocol ServiceLayer {}
protocol PresentationLayer {}

// They can be used like this:
class SomeServiceImplementation: SomeService, ServiceLayer {
    @Injected
    private var somethingFromServiceContainer: Something
}

class SomeScreenFlow: SomeService, PresentationLayer {
    @Injected
    private var somethingForUIOnly: Something
}

// Somewhere before classes creation:
let serviceContainer = Container(parent: ContainerSelector.defaultContainer)
let presentationContainer = Container(parent: serviceContainer)

ContainerSelector.for = { enclosedObject in
    switch enclosedObject {
        case is ServiceLayer: return serviceContainer
        case is PresentationLayer: return presentationContainer
        default: return ContainerSelector.defaultContainer
    }
}
```

This is one of the ways to do that. Feel free to use anything you need.
