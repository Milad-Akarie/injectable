# injectable:

Injectable is a convenient code generator for [get_it](https://pub.dev/packages/get_it). Inspired by Angular DI and inject.dart.

---

- [Installation](#installation)
- [Setup and Usage](#setup-and-usage)
- [Custimization](#custimization)

### Installation

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

### Setup

---

1- Create a configure function in a new file and annotate it with @injectConfig.
2- in your configure func call $initGetIt()
**$initGetIt()\*\* will be inside of the generated file example.iconfig.dart

```dart
@injectConfig
void configure() => $initGetIt();
```

4- Call configure() in your main func before running the App

```daret
void main() {
 configure();
 runApp(MyApp());
}
```

### Usage

---

All you have to do is annotate your injectable classes with @injectable and let the generator do the work.

```dart
@injectable
class ServiceA {}

@injectable
class ServiceB {
    ServiceB(ServiceA serviceA);
}

```

#### Run the generator

Use the [watch] flag to watch the files system for edits and rebuild as necessary.

```terminal
flutter packages pub run build_runner watch
```

if you want the generator to run one time and exits use

```terminal
flutter packages pub run build_runner build
```

#### Inside of the generated file

```dart
void $initGetIt({String environment}) {
 final getIt = GetIt.instance;
  getIt..registerFactory<ServiceA>(() => ServiceA())
       ..registerFactory<ServiceB>(ServiceA(getIt<ServiceA>()))
}
```

### Custimization

---

##### @AutoRouter

| Property                 | Default value | Definition                                                      |
| ------------------------ | ------------- | --------------------------------------------------------------- |
| generateNavigator [bool] | true          | if true a navigator key will be generated with helper accessors |
| generateRouteList [bool] | false         | if true a list of all routes will be generated                  |

#### @MaterialRoute | @CupertinotRoute | @CustomeRoute

| Property                | Default value | Definition                                                                                 |
| ----------------------- | :-----------: | ------------------------------------------------------------------------------------------ |
| initial [bool]          |     false     | mark the route as initial '\\'                                                             |
| name [String]           |     null      | this will be assigned to the route variable name if provided (String homeScreen = [name]); |
| fullscreenDialog [bool] |     false     | extenstion for the fullscreenDialog property in PageRoute                                  |
| maintainState [bool]    |     true      | extenstion for the maintainState property in PageRoute                                     |

#### @CupertinotRoute Specific => CupertinoPageRoute

| Property       | Default value | Definition                                              |
| -------------- | :-----------: | ------------------------------------------------------- |
| title [String] |     null      | extenstion for the title property in CupertinoPageRoute |

#### @CustomeRoute Specific => PageRouteBuilder

| Property                        | Default value | Definition                                                                       |
| ------------------------------- | :-----------: | -------------------------------------------------------------------------------- |
| transitionsBuilder [Function]   |     null      | extenstion for the transitionsBuilder property in PageRouteBuilder               |
| opaque [bool]                   |     true      | extenstion for the opaque property in PageRouteBuilder                           |
| barrierDismissible [bool]       |     false     | extenstion for the barrierDismissible property in PageRouteBuilder               |
| durationInMilliseconds [double] |     null      | extenstion for the transitionDuration(milliSeconds) property in PageRouteBuilder |

### Problems with the generation?

---

Make sure you always **Save** your files before running the generator, if that doesn't work you can always try to clean and rebuild.

```terminal
flutter packages pub run build_runner clean
```
