# injectable_generator

A generator for [injectable](https://pub.dev/packages/injectable) library.

## injectable

Injectable is a convenient code generator for [get_it](https://pub.dev/packages/get_it). Inspired by Angular DI, Guice DI and inject.dart.

---

- [Installation](#installation)
- [Setup](#setup)
- [Registering factories](#registering-factories)
- [Registering singletons](#registering-singletons)
- [Binding abstract classes to implementations](#binding-abstract-classes-to-implementations)
- [Register under different environments](#register-under-different-environments)
- [Auto registering $Experimental$](#auto-registering-$experimental$)

## Installation

```yaml
dependencies:
  # add injectable to your dependencies
  injectable:
  # add get_it
  get_It:

dev_dependencies:
  # add the generator to your dev_dependencies
  injectable_generator:
  # of course build_runner is needed to run the generator
  build_runner:
```

## Setup

---

1- Create a new dart file and define a top-level function (lets call it configure) then annotate it with @injectableInit.
2- Call the **Generated** func \$initGetIt() inside your confiugre func.

```dart
@injectableInit
void configure() => $initGetIt();
```

3- Call configure() in your main func before running the App

```daret
void main() {
 configure();
 runApp(MyApp());
}
```

## Registering factories

---

All you have to do now is annotate your injectable classes with @injectable and let the generator do the work.

```dart
@injectable
class ServiceA {}

@injectable
class ServiceB {
    ServiceB(ServiceA serviceA);
}

```

### Run the generator

Use the [watch] flag to watch the files system for edits and rebuild as necessary.

```terminal
flutter packages pub run build_runner watch
```

if you want the generator to run one time and exits use

```terminal
flutter packages pub run build_runner build
```

### Inside of the generated file

Injectable will generate the needed register functions for you

```dart
final getIt = GetIt.instance;

void $initGetIt({String environment}) {
  getIt..registerFactory<ServiceA>(() => ServiceA())
       ..registerFactory<ServiceB>(ServiceA(getIt<ServiceA>()))
}
```

## Registering singletons

---

Simply add the @singleton or @lazySingleton annotations to your class.
Alternatively use the constructor version to pass signalsReady to getIt.registerSingleton(signalsReady)
@Singleton(signalsReady: true) >> getIt.registerSingleton(Model(), signalsReady: true)
@Singleton.lazy(signalsReady: true) >> getIt.registerLazySingleton(() => Model(), signalsReady: true)

```dart
@singleton // or @lazySingleton
@injectable
class ApiProvider {}
```

## Binding abstract classes to implementations

---

Use the @Bind annotation to bind abstract types to their implementations.
**Note:** the passed type needs to implement or extend the annotated type.

```dart
@Bind.toType(ServiceImpl)
@injectable
abstract class Service {}
```

Generated code for the Above example

```dart
getIt.registerFactory<Service>(() => ServiceImpl())
```

### Binding an abstract class to multiable implementations

Since we can't use type binding to register more than one implementation, we have to use names (tags)
to register our instances.

```dart
@Bind.toNamedType(ServiceImpl1, name: 'impl1')
@Bind.toNamedType(ServiceImpl2, name: 'impl2')
@injectable
abstract class Service {}
```

Next annotate the injected instance with @Named() right in the construcor and pass in the name of the desired implementation.

```dart
@injectable
class MyRepo {
   final Service service;
    MyRepo(@Named('impl1') this.service)
}
```

Generated code for the Above example

```dart
getIt.registerFactory<Service>(() => ServiceImpl1(), instanceName: 'impl1')
getIt.registerFactory<Service>(() => ServiceImpl2(), instanceName: 'impl2')

getIt.registerFactory<MyRepo>(() => MyRepo(getIt('impl1'))
```

### Auto Tagging

if you don't pass a name to Bind.toNamedType() the implementation type name will be used
@Bind.toNamedType(ServiceImpl1) == @Bind.toNamedType(ServiceImpl1, name: 'ServiceImpl1')
Then use @Named.from(Type) annotation to extract the name from the type

```dart
@Bind.toNamedType(ServiceImpl1)
@injectable
abstract class Service {}

@injectable
class MyRepo {
   final Service service;
    MyRepo(@Named.from(ServiceImpl1) this.service)
}
```

Generated code for the Above example

```dart
getIt.registerFactory<Service>(() => ServiceImpl1(), instanceName: 'ServiceImpl1')
getIt.registerFactory<MyRepo>(() => MyRepo(getIt('ServiceImpl1'))
```

## Register under different environments

---

it is possible to register different dependencies for different environments by using **@Environment('name')** annotation.
in the below example ServiceA is now only registered if we pass the environment name to \$initGetIt(envirnoment: 'dev')

```dart
@Environment("dev")
@injectable
class ServiceA {}
```

Generated code for the Above example

```dart
void $initGetIt({String environment}) {
 // ... other deps
  if (environment == 'dev') {
    _registerDevDependencies();
  }
}
```

Usually you would want to register a diffirent implmenetation for the same abstract class under diffrent envirnoments.
to do that pass your environment name to the Bind annotation

```dart
@Bind.toType(FakeServiceImple, env: 'dev')
@Bind.toType(RealServiceImple, env: 'prod')
@injectable
abstract class Service {}
```

Generated code for the Above example

```dart
void $initGetIt({String environment}) {
// ..other deps
  if (environment == 'dev') {
    _registerDevDependencies();
  }
  if (environment == 'prod') {
    _registerProdDependencies();
  }
}

void _registerDevDependencies() {
  getIt.registerFactory<Service>(() => FakeServiceImple());
  // ..other dev deps
}

void _registerProdDependencies() {
  getIt.registerFactory<Service>(() => RealServiceImple());
    // ..other prod deps
}

```

## Auto registering $Experimental$

---

Instead of annotating every single injectable class you write, it is possible to use a [Convention Based Configruation](https://en.wikipedia.org/wiki/Convention_over_configuration) to auto register your injectable classes, espeically if you follow a consice naming convention.

for example you can tell the generator to auto-register any class that ends with Service, Repository or Bloc
using a simple regex pattern
class_name_pattern: 'Service$|Repository$|Bloc\$'
To use auto-register create a file with the name **build.yaml** in the same directory as **pubspec.yaml** and add

```yaml
targets:
  $default:
    builders:
      injectable_generator:injectable_builder:
        options:
          auto_register: true
          # auto register any class with a name matches the given pattern
          class_name_pattern:
            "Service$|Repository$|Bloc$"
            # auto register any class inside a file with a
            # name matches the given pattern
          file_name_pattern: "_service$|_repository$|_bloc$"
```

## Problems with the generation?

---

Make sure you always **Save** your files before running the generator, if that doesn't work you can always try to clean and rebuild.

```terminal
flutter packages pub run build_runner clean
```

## Support the Library

- You can support the library by staring in on Github or report any bugs you encounter.
- also you have a suggestion or think something can be implemented in a better way, open an issue and lets talk about it.
