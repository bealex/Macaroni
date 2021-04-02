# Migrations

## From version 1.x to version 2.x

If you use only one `Scope`:
 - `ContainerFactory` can be renamed to `Configurator`, remove superclass/protocol implementation, and `override` from `build` method.
 - `build` method does not need to return `Container` anymore. Replace container creation with `ContainerSelector.defaultContainer`.
 - Register all dependencies in `ContainerSelector.defaultContainer`.

If you use several scopes:
 - Create several containers, as in version 1.x (and remove all factory inheritance in the process).
 - Override `ContainerSelector.for` closure to select appropriate container for specified enclosing class.

### Parametrized dependencies
If you used some workaround for registering and initializing dependencies that require enclosing class information, please re-register them with new registration method: `Container.register<D>(_ resolver: @escaping (_ parameter: Any) -> D)`. If you use `@Injected`, parameter there will be enclosing class itself, you can use it to initialize injected instance.

### Example

Common part:
```swift
protocol MyService {}
class MyServiceImplementation: MyService {}
```

And common usage:
```swift
class MyController {
    @Injected
    var myService: MyService
}

let controller = MyController()
controller.testInjection()
```

#### Simple injection

v 1.x:

```swift
// Services creation and registration:
class MyContainerFactory: SingletonContainerFactory {
    override func build() -> Container {
        let container = SimpleContainer()
        let myService = MyServiceImplementation()
        container.register { () -> MyService in myService }
        return container
    }
}

// Somewhere at application launch:
Scope.default = Scope(factory: MyContainerFactory())
```

v 2.x:

```swift
// Somewhere at application launch:
let container = Container()
Container.policy = .singleton(container)

// Services creation and registration:
let myService = MyServiceImplementation()
container.register { () -> MyService in myService }
```

#### Parametrized injection

v 1.x

This depends on option you've chosen. Complex every time. :-( Simplest thing will be to create another `@InjectedWithParameter` with additional properties, that will provide needed information. For example, if logger should have a specific label, it can be used like this:

```swift
// @InjectedLabeledLogger definition somewhere here
// Registration: not needed, all work is done in @InjectedLabeledLogger  
// Usage
class MyController {
    @InjectedLabeledLogger("MyController")
    var logger: LabeledLogger
}
```

v 2.x

```swift
// Registration
func build() {
    let myService = MyServiceImplementation()
    ContainerSelector.defaultContainer.register { parameter -> LabeledLogger in 
        LabeledLogger(object: parameter, logger: rootLogger) 
    }
}

// Usage
class MyController {
    @Injected
    var logger: LabeledLogger
}
```
