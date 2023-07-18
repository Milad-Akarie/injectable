/// Marks a top-level function as an initializer function
/// for configuring Get_it
class InjectableInit {
  /// Only files exist in provided directories will be processed
  final List<String> generateForDir;

  /// if true relative imports will be used where possible
  /// defaults to false
  final bool preferRelativeImports;

  /// generated initializer name
  /// defaults to $init
  final String initializerName;

  /// if true the init function
  /// will be generated inside
  /// of a [GetIi] extension
  /// defaults to true
  final bool asExtension;

  /// weather to include null-safety
  /// suffixes to the generated code;
  final bool usesNullSafety;

  ///  generator will not show warning for unregistered types
  ///  included in this list
  final List<Type> ignoreUnregisteredTypes;

  ///  generator will not show warning for unregistered types if import start with any string
  ///  included in this list
  final List<String> ignoreUnregisteredTypesInPackages;

  /// indicates whether the package using the annotation
  /// is a microPackage, in that case a  different
  /// output will be generated.
  // ignore: unused_field
  final bool _isMicroPackage;

  /// weather or not the main initializers
  /// should include micro package modules
  /// defaults to true
  final bool includeMicroPackages;

  /// throw an error and abort generation
  /// in case of missing dependencies
  /// defaults to false
  final bool throwOnMissingDependencies;

  /// a List of external package modules to be registered
  /// in the default package initializer
  /// classes passed here must extend [MicroPackageModule]
  @Deprecated('use externalPackageModulesBefore instead')
  final List<Type>? externalPackageModules;

  /// a List of external package modules to be registered
  /// in the default package initializer before root dependencies
  /// classes passed here must extend [MicroPackageModule]
  final List<ExternalModule>? externalPackageModulesBefore;

  /// a List of external package modules to be registered
  /// in the default package initializer after root dependencies
  /// classes passed here must extend [MicroPackageModule]
  final List<ExternalModule>? externalPackageModulesAfter;

  /// If [createGetItHelper] is true, an additional top-level get_it instance
  /// will be extracted for micro modules.
  final bool createGetItHelper;

  /// default constructor
  const InjectableInit({
    this.generateForDir = const ['lib'],
    this.preferRelativeImports = false,
    this.initializerName = 'init',
    this.ignoreUnregisteredTypes = const [],
    this.ignoreUnregisteredTypesInPackages = const [],
    this.asExtension = true,
    this.usesNullSafety = true,
    this.externalPackageModules,
    this.throwOnMissingDependencies = false,
    this.includeMicroPackages = true,
    this.externalPackageModulesAfter,
    this.externalPackageModulesBefore,
  })  : _isMicroPackage = false,
        createGetItHelper = false;

  /// default constructor
  const InjectableInit.microPackage({
    this.generateForDir = const ['lib'],
    this.preferRelativeImports = false,
    this.ignoreUnregisteredTypes = const [],
    this.externalPackageModules,
    this.externalPackageModulesAfter,
    this.externalPackageModulesBefore,
    this.throwOnMissingDependencies = false,
    this.ignoreUnregisteredTypesInPackages = const [],
    this.usesNullSafety = true,
    this.createGetItHelper = false,
  })  : _isMicroPackage = true,
        asExtension = false,
        includeMicroPackages = false,
        initializerName = 'init';
}

/// const instance of [InjectableInit]
/// with default arguments
const injectableInit = InjectableInit();

/// const instance of [InjectableInit.microPackage]
/// with default arguments
const microPackageInit = InjectableInit.microPackage();

/// Marks a class as an injectable
/// dependency and generates
class Injectable {
  /// The type to bind your implementation to,
  /// typically, an abstract class which is implemented by the
  /// annotated class.
  final Type? as;

  /// an alternative way to pass env keys instead
  /// of annotating the element with @Environment
  final List<String>? env;

  /// an alternative way to pass position order instead
  /// of annotating the element with @Order
  final int? order;

  /// an alternative way to pass position scope instead
  /// of annotating the element with @Scope
  final String? scope;

  /// default constructor
  const Injectable({this.as, this.env, this.scope, this.order});
}

/// const instance of [Injectable]
/// with default arguments
const injectable = Injectable();

/// Classes annotated with @Singleton
/// will generate registerSingleton function
class Singleton extends Injectable {
  /// passed to singlesReady property
  /// in registerSingleton function
  final bool? signalsReady;

  /// passed to dependsOn property
  /// in registerSingleton function
  final List<Type>? dependsOn;

  /// a dispose callback function to be
  /// passed to [GetIt]
  /// the signature must match FutureOr dispose(T)
  final Function? dispose;

  /// default constructor
  const Singleton({
    this.signalsReady,
    this.dependsOn,
    this.dispose,
    Type? as,
    List<String>? env,
    String? scope,
    int? order,
  }) : super(
    as: as,
    env: env,
    order: order,
    scope: scope,
  );
}

/// const instance of [Singleton]
/// with default arguments
const singleton = Singleton();

/// Classes annotated with @LazySingleton
/// will generate registerLazySingleton func
class LazySingleton extends Injectable {
  /// default constructor
  const LazySingleton({
    Type? as,
    List<String>? env,
    this.dispose,
    String? scope,
    int? order,
  }) : super(
    as: as,
    env: env,
    scope: scope,
    order: order,
  );

  /// a dispose callback function to be
  /// passed to [GetIt]
  /// the signature must match FutureOr dispose(T)
  final Function? dispose;
}

/// const instance of [LazySingleton]
/// with default arguments
const lazySingleton = LazySingleton();

/// Used to register a dependency under a name
/// instead of type also used to annotated
/// named injected dependencies in constructors
class Named {
  /// The name in which an instance is registered
  final String? name;

  /// default constructor
  const Named(this.name) : type = null;

  /// instead of providing a literal name
  /// you can pass a type, and its name will be extracted
  /// in during generation
  final Type? type;

  /// A named constrictor to extract name for type
  const Named.from(this.type) : name = null;
}

/// const instance of [Named]
/// with default arguments
const named = Named('');

/// Used to annotate dependencies which are
/// registered under certain environments
class Environment {
  /// name of the environment
  final String name;

  /// default constructor
  const Environment(this.name);

  /// preset of common env name 'dev'
  static const dev = 'dev';

  /// preset of common env name 'prod'
  static const prod = 'prod';

  /// preset of common env name 'test'
  static const test = 'test';
}

/// instance name for the Set of environment
/// keys that's registered internally inside of
/// [GetItHelper]
const kEnvironmentsName = '__environments__';
const kEnvironmentsFilterName = '__environments__filter__';

/// preset instance of common env name
const dev = Environment(Environment.dev);

/// preset instance of common env name
const prod = Environment(Environment.prod);

/// preset instance of common env name
const test = Environment(Environment.test);

/// Marks a factory, a named constructor or a static create
/// function as an injectable constructor
/// if not added the default constructor will be used.
class FactoryMethod {
  /// return value will be pre-awaited before it's
  /// registered inside of GetIt
  final bool preResolve;

  // default constructor
  const FactoryMethod({this.preResolve = false});
}

/// const instance of [FactoryMethod]
/// with default values
const factoryMethod = FactoryMethod();

/// Marks a constructor param as
/// factoryParam so it can be passed
/// to the resolver function
class FactoryParam {
  const FactoryParam._();
}

/// const instance of [FactoryParam]
/// with default arguments
const factoryParam = FactoryParam._();

/// marks a class as a register module where all
/// property accessors rerun types are considered factories
/// unless annotated with @singleton/lazySingleton.
class Module {
  const Module._();
}

/// const instance of [Module]
/// with default arguments
const module = Module._();

/// Futures annotated with [preResolve]
/// will be pre-awaited before they're
/// registered inside of GetIt
class PreResolve {
  const PreResolve._();
}

/// const instance of [PreResolve]
/// with default arguments
const preResolve = PreResolve._();

/// methods annotated with [postConstruct]
/// will be called in a cascade manner
/// after being constructed
class PostConstruct {
  /// return value will be pre-awaited before it's
  /// registered inside of GetIt
  final bool preResolve;

  // default constructor
  const PostConstruct({this.preResolve = false});
}

/// const instance of [PostConstruct]
/// with default arguments
const postConstruct = PostConstruct();

/// marks an instance method as a dispose
/// call back to be passed to [GetIt]
class DisposeMethod {
  const DisposeMethod._();
}

/// const instance of [DisposeMethod]
/// with default arguments
const disposeMethod = DisposeMethod._();

/// Classes annotated with @Order will overwrite
/// the automatically generated position of the
class Order {
  /// determines the position in the order of generated GetIt functions
  final int position;

  /// default constructor
  const Order(this.position);
}

/// const instance of [Order]
/// with default arguments
const order = Order(0);

/// Used to annotate dependencies which are
/// registered under a different scope than main-scope
class Scope {
  /// name of the scope
  final String name;

  /// default constructor
  const Scope(this.name);
}

class ExternalModule {
  final Type module;
  final String? scope;

  const ExternalModule(this.module, {this.scope});
}
