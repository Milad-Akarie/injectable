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

class Env {
  final String name;

  const Env(this.name);

  static const dev = 'dev';
  static const prod = 'prod';
  static const test = 'test';
}

const dev = const Env(Env.dev);
const prod = const Env(Env.prod);
const test = const Env(Env.test);

class Bind {
  // The type to bind your implementation to,
  // typically an abstract class which is implemented by the
  // annotated class.
  final Type type;
  final Type to;
  final String env;
  final bool _standAlone;

  const Bind(this.type, {this.to, this.env})
      : _standAlone = true,
        assert(to != null);

  const Bind.toAbstract(this.to, {this.env})
      : this.type = null,
        this._standAlone = false;
}

class FactoryMethod {
  const FactoryMethod._();
}

const factoryMethod = const FactoryMethod._();
