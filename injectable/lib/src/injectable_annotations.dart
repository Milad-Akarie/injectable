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
class Singleton {
  final bool signalsReady;
  final bool _lazy;
  const Singleton({this.signalsReady}) : _lazy = false;
  const Singleton.lazy({this.signalsReady}) : _lazy = true;
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

class Environment {
  final String name;
  const Environment(this.name);

  static const development = 'development';
  static const production = 'production';
}

const development = const Environment(Environment.development);
const production = const Environment(Environment.production);

class Bind {
  // Passed to instanceName argument in
  // getIt register function
  final String name;

  // The type to bind your implementation to,
  // typically an abstract class which is implemented by the
  // annotated class.
  final Type type;

  final bool _isNamed;

  final String env;

  const Bind.toType(this.type, {this.env})
      : this.name = null,
        _isNamed = false;

  const Bind.toNamedtype(this.type, {this.name, this.env}) : _isNamed = true;

  const Bind.toName(this.name)
      : _isNamed = true,
        this.env = null,
        this.type = null;
}
