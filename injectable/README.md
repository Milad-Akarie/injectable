# injectable

Injectable is a convenient code generator for [get_it](https://pub.dev/packages/get_it). Inspired by Angular DI, Guice DI and inject.dart.

---

- [Installation](#installation)
- [Setup](#setup)
- [Registering factories](#registering-factories)
- [Registering singletons](#registering-singletons)
- [Binding abstract classes to implementations](#binding-abstract-classes-to-implementations)
- [Register under different environments](#register-under-different-environments)
- [Using named factories and static create functions](#Using-named-factories-and-static-create-functions)
- [Registering third party types](#Registering-third-party-types)
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

.1 Create a new dart file and define a global var for your GetIt instance
.2 Define a top-level function (lets call it configure) then annotate it with @injectableInit.
.3 Call the **Generated** func \$initGetIt() inside your configure func and pass in the getIt instance.

```dart
final getIt = GetIt.instance;

@injectableInit
void configure() => $initGetIt(getIt);
```

.4 Call configure() in your main func before running the App

```dart
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

void $initGetIt(GetIt g, {String environment}) {
  g.registerFactory<ServiceA>(() => ServiceA())
  g.registerFactory<ServiceB>(ServiceA(getIt<ServiceA>()))
}
```

## Registering singletons

---

Use the @singleton or @lazySingleton to annotate your singleton classes.
Alternatively use the constructor version to pass signalsReady to getIt.registerSingleton(signalsReady)
@Singleton(signalsReady: true) >> getIt.registerSingleton(Model(), signalsReady: true)
@Singleton.lazy(signalsReady: true) >> getIt.registerLazySingleton(() => Model(), signalsReady: true)

```dart
@singleton // or @lazySingleton
class ApiProvider {}
```

## Binding abstract classes to implementations

---

Use the @RegisterAs annotation to bind an abstract class to it's implementation.
**Annotate the implementation not the abstract class**

```dart
@RegisterAs(Service)
@injectable
class ServiceImpl {}
```

Generated code for the Above example

```dart
g.registerFactory<Service>(() => ServiceImpl())
```

### Binding an abstract class to multiable implementations

Since we can't use type binding to register more than one implementation, we have to use names (tags)
to register our instances or register under different environment. (we will get to that later)

```
@Named("impl1")
@RegisterAs(Service)
@injectable
class ServiceImpl implements Service {}

@Named("impl2")
@RegisterAs(Service)
@injectable
class ServiceImp2 implements Service {}
```

Next annotate the injected instance with @Named() right in the constructor and pass in the name of the desired implementation.

```dart
@injectable
class MyRepo {
   final Service service;
    MyRepo(@Named('impl1') this.service)
}
```

Generated code for the Above example

```dart
g.registerFactory<Service>(() => ServiceImpl1(), instanceName: 'impl1')
g.registerFactory<Service>(() => ServiceImpl2(), instanceName: 'impl2')

g.registerFactory<MyRepo>(() => MyRepo(getIt('impl1'))
```

### Auto Tagging

Use the lower cased @named annotation to automatically assign the implementation class name to the instance name.
Then use @Named.from(Type) annotation to extract the name from the type

```dart
@named
@RegisterAs(Service)
@injectable
 class ServiceImpl1 implements Service {}

@injectable
class MyRepo {
   final Service service;
    MyRepo(@Named.from(ServiceImpl1) this.service)
}
```

Generated code for the Above example

```dart
g.registerFactory<Service>(() => ServiceImpl1(), instanceName: 'ServiceImpl1')
g.registerFactory<MyRepo>(() => MyRepo(getIt('ServiceImpl1'))
```

## Register under different environments

---

it is possible to register different dependencies for different environments by using **@Environment('name')** annotation.
in the below example ServiceA is now only registered if we pass the environment name to \$initGetIt(environment: 'dev')

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

you could also create your own environment annotations by assigning the const constructor Enviromnent("") to a global const var.

```dart
const dev = const Environment('dev');
// then just use it to annotate your classes
@dev
@injectable
class ServiceA {}
```

Usually you would want to register a different implementation for the same abstract class under different environments.
to do that pass your environment name to the @RegisterAs annotation or use @Environment("env") annotation.

```dart
@RegisterAs(Service, env: 'dev')
// or @Environment('dev')
@injectable
class FakeServiceImpl implements Service {}

@RegisterAs(Service, env: 'prod')
@injectable
class RealServiceImpl implements Service {}
```

Generated code for the Above example

```dart
void $initGetIt(GetIt getIt, {String environment}) {
// ..other deps
  if (environment == 'dev') {
    _registerDevDependencies(g);
  }
  if (environment == 'prod') {
    _registerProdDependencies(g);
  }
}

void _registerDevDependencies(GetIt g) {
  g.registerFactory<Service>(() => FakeServiceImpl());
  // ..other dev deps
}

void _registerProdDependencies(GetIt g) {
  g.registerFactory<Service>(() => RealServiceImpl());
    // ..other prod deps
}

```

## Using named factories and static create functions

---

By default injectable will use the default constructor to build your dependencies but, you can tell injectable to use named/factory constructors or static create functions by using the @factoryMethod annotation. .

```dart
@injectable
class MyRepository {
  @factoryMethod
  MyRepository.from(Service s);
}
```

The constructor named "from" will be used when building MyRepository.

```dart
g.registerFactory<MyRepository>(MyRepository.from(getIt<Service>()));
```

or annotate static create functions or factories inside of abstract classes with @factoryMethod

```dart
@injectable
abstract class Service {
  @factoryMethod
  static ServiceImpl2 create(ApiClient client) => ServiceImpl2(client);

  @factoryMethod
  factory Service.from() => ServiceImpl();
}
```

Generated code.

```dart
g.registerFactory<Service>(() => Service.create(getIt<ApiClient>()));
```

## Registering third party types

---

To Register third party types, create an abstract class and annotate it with @registerModule then add your third party types as property accessors like follows:

```dart
@registerModule
abstract class RegisterModule {
  @singleton
  ThirdPartyType get thirdPartyType;

  @prod
  @RegisterAs(ThirdPartyAbstract)
  ThirdPartyImpl get thirdPartyType;
}
```

### Providing custom initializers

In some cases you'd need to register instances that are asynchronous or singleton instances or just have a custom initializer and that's a bit hard for injectable to figure out on it's own, so you need to tell injectable how to initialize them;

```dart
@registerModule
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(baseUrl: "baseUrl"));
  // same thing works for instances that's gotten asynchronous.
  // all you need to do is wrap your instance with a future and tell injectable how
  // to initialize it
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
  // Also make sure you await for your configure function before running the App.
}
```

generated code

```dart
Future<void> $initGetIt(GetIt g, {String environment}) async {
  g.lazySingleton<Dio>(() => Dio(BaseOptions(baseUrl: "baseUrl")));
  final sharedPreferences = await SharedPreferences.getInstance();
  g.registerFactory<SharedPreferences>(() => sharedPreferences);
}
```

#### The limitation when providing custom initializers.

- You can only use arrow functions (Expressions) => "at least for now"
- Dependencies used in the custom initializers can not be imported automatically, meaning if you use any dependencies in your custom initializer make sure they're registered individually.

if you're facing even a weirder scenario you can always register them manually in the configure function.

## Auto registering $Experimental$

---

Instead of annotating every single injectable class you write, it is possible to use a [Convention Based Configuration](https://en.wikipedia.org/wiki/Convention_over_configuration) to auto register your injectable classes, especially if you follow a concise naming convention.

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

- You can support the library by staring it on Github or report any bugs you encounter.
- also if you have a suggestion or think something can be implemented in a better way, open an issue and lets talk about it.
