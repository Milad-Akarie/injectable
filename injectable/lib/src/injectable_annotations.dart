class InjectableInit {
  const InjectableInit._();
}

const injectableInit = const InjectableInit._();

class Injectable {
  const Injectable._();
}

const injectable = const Injectable._();

/// Classes annotated with @Singleton
/// will generate registerSingleton  or
/// registerLazySingleton if [_lazy] is true
class Singleton extends Injectable {
  final bool signalsReady;
  final bool _lazy;

  const Singleton({this.signalsReady})
      : _lazy = false,
        super._();

  const Singleton.lazy({this.signalsReady})
      : _lazy = true,
        super._();
}

const singleton = const Singleton();
const lazySingleton = const Singleton.lazy();

// Used to annotate a constructor dependency
// that's registered with an instance names;
class Named {
  // the name in which an instance is registered
  final String name;

  const Named(this.name) : type = null;

  // instead of providing a literal name
  // you can pass a type and it's name will be extrected
  // in during generation
  final Type type;
  const Named.from(this.type) : name = null;
}

const named = const Named("");

class Envirnoment {
  final String name;

  const Envirnoment(this.name);

  static const dev = 'dev';
  static const prod = 'prod';
  static const test = 'test';
}

const dev = const Envirnoment(Envirnoment.dev);
const prod = const Envirnoment(Envirnoment.prod);
const test = const Envirnoment(Envirnoment.test);

class RegisterAs {
  // The type to bind your implementation to,
  // typically an abstract class which is implemented by the
  // annotated class.
  final Type abstractType;
  // an alternative way to pass env keys insted
  // of annotated the element with @Environment
  final String env;

  const RegisterAs(this.abstractType, {this.env});
}

// Marks a factory, a named constructor or a static create
// function as an injectable constructor
// if not added the defualt constructor will be used.
class FactoryMethod {
  const FactoryMethod._();
}

const factoryMethod = const FactoryMethod._();

// marks a class as a register module where all
// property accessors retrun types are considered factories
// unless annotated with @singleton/lazySingelton.
class RegisterModule {
  const RegisterModule._();
}

const registerModule = const RegisterModule._();
