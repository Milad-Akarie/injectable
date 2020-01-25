class InjectableConfig {
  const InjectableConfig._();
}

const injectableInit = const InjectableConfig._();

class Injectable {
  // Passed to instanceName argument in
  // getIt register function
  final String instanceName;

  // The type to bind your implementation to,
  // typically an abstract class which is implemented by the
  // annotated class.
  final Type bindTo;

  const Injectable({this.instanceName, this.bindTo});
}

const injectable = const Injectable();

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
class InstanceName {
  // the name in which an instance is registered
  final String name;
  const InstanceName(this.name) : assert(name != null);
}

class Environment {
  final String name;
  const Environment(this.name);

  static const development = 'development';
  static const production = 'production';
}

const development = const Environment(Environment.development);
const production = const Environment(Environment.production);
