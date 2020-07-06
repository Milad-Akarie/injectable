class InjectableInit {
  // only files exist in provided directories will be processed
  final List<String> generateForDir;

  const InjectableInit({this.generateForDir = const ['lib', 'bin']})
      : assert(generateForDir != null);
}

const injectableInit = InjectableInit();

class Injectable {
  // The type to bind your implementation to,
  // typically an abstract class which is implemented by the
  // annotated class.
  final Type as;

  // an alternative way to pass env keys instead
  // of annotating the element with @Environment
  final String env;

  const Injectable({this.as, this.env});
}

const injectable = Injectable();

/// Classes annotated with @Singleton
/// will generate registerSingleton func
class Singleton extends Injectable {
  final bool signalsReady;
  final List<Type> dependsOn;

  const Singleton({
    this.signalsReady,
    this.dependsOn,
    Type as,
    String env,
  }) : super(as: as, env: env);
}

const singleton = Singleton();

/// Classes annotated with @LazySingleton
/// will generate registerLazySingleton func
class LazySingleton extends Injectable {
  const LazySingleton({
    Type as,
    String env,
  }) : super(as: as, env: env);
}

const lazySingleton = LazySingleton();

// Used to annotate a constructor dependency
// that's registered with an instance names;
class Named {
  // the name in which an instance is registered
  final String name;

  const Named(this.name) : type = null;

  // instead of providing a literal name
  // you can pass a type and it's name will be extracted
  // in during generation
  final Type type;

  const Named.from(this.type) : name = null;
}

const named = Named('');

// used to annotate dependencies which are
// registered under different environment
class Environment {
  final String name;

  const Environment(this.name);

  static const dev = 'dev';
  static const prod = 'prod';
  static const test = 'test';
}

const dev = Environment(Environment.dev);
const prod = Environment(Environment.prod);
const test = Environment(Environment.test);

@Deprecated("Use @Injectable(as:...) or it's subs instead")
// @Injectable(as: Type)
// @Singleton(as: Type)
// @LazySingleton(as: Type)
class RegisterAs {
  // The type to bind your implementation to,
  // typically an abstract class which is implemented by the
  // annotated class.
  final Type abstractType;

  // an alternative way to pass env keys instead
  // of annotating the element with @Environment
  final String env;

  const RegisterAs(this.abstractType, {this.env});
}

// Marks a factory, a named constructor or a static create
// function as an injectable constructor
// if not added the default constructor will be used.
class FactoryMethod {
  const FactoryMethod._();
}

const factoryMethod = FactoryMethod._();

/// Marks a constructor param as
/// factoryParam so it can be passed
/// to the resolver function
class FactoryParam {
  const FactoryParam._();
}

const factoryParam = FactoryParam._();

// marks a class as a register module where all
// property accessors rerun types are considered factories
// unless annotated with @singleton/lazySingleton.
class RegisterModule {
  const RegisterModule._();
}

@Deprecated('Use module instead')
const registerModule = RegisterModule._();

const module = RegisterModule._();

/// Futures annotated with [preResolv]
/// will be pre-awaited before they're
/// registered inside of GetIt
class PreResolve {
  const PreResolve._();
}

const preResolve = PreResolve._();
