import 'package:get_it/get_it.dart';

typedef EnvironmentFilter = bool Function(Set<String>);

/// a helper class to handle conditional registering
class GetItHelper {
  /// passed getIt instance
  final GetIt getIt;

  /// current work environment
  final String environment;

  /// filter for whether to register for the given set of environments
  final EnvironmentFilter environmentFilter;

  /// creates a new instance of GetItHelper
  GetItHelper(this.getIt, [this.environment, this.environmentFilter])
      : assert(getIt != null),
        assert(environmentFilter == null || environment == null);

  /// if a dependency is registered under certain environments
  /// one of theme needs to match the current [environment]
  /// to register
  bool _shouldRegister(Set<String> registerFor) {
    return registerFor == null ||
        environmentFilter?.call(registerFor) ?? registerFor.contains(environment);
  }

  /// a conditional wrapper method for getIt.registerFactory
  /// it only registers if [_shouldRegister] returns true
  void factory<T>(
    FactoryFunc<T> factoryfunc, {
    String instanceName,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerFactory<T>(factoryfunc, instanceName: instanceName);
    }
  }

  /// a conditional wrapper method for getIt.registerFactoryAsync
  /// it only registers if [_shouldRegister] returns true
  void factoryAsync<T>(
    FactoryFuncAsync<T> factoryfunc, {
    String instanceName,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerFactoryAsync<T>(factoryfunc, instanceName: instanceName);
    }
  }

  /// a conditional wrapper method for getIt.registerFactoryParam
  /// it only registers if [_shouldRegister] returns true
  void factoryParam<T, P1, P2>(
    FactoryFuncParam<T, P1, P2> factoryfunc, {
    String instanceName,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerFactoryParam<T, P1, P2>(
        factoryfunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerFactoryParamAsync
  /// it only registers if [_shouldRegister] returns true
  void factoryParamAsync<T, P1, P2>(
    FactoryFuncParamAsync<T, P1, P2> factoryfunc, {
    String instanceName,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerFactoryParamAsync<T, P1, P2>(
        factoryfunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerLazySingleton
  /// it only registers if [_shouldRegister] returns true
  void lazySingleton<T>(
    FactoryFunc<T> factoryfunc, {
    String instanceName,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerLazySingleton<T>(
        factoryfunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerLazySingletonAsync
  /// it only registers if [_shouldRegister] returns true
  void lazySingletonAsync<T>(
    FactoryFuncAsync<T> factoryfunc, {
    String instanceName,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerLazySingletonAsync<T>(
        factoryfunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerSingleton
  /// it only registers if [_shouldRegister] returns true
  void singleton<T>(
    T instance, {
    String instanceName,
    bool signalsReady,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerSingleton<T>(
        instance,
        instanceName: instanceName,
        signalsReady: signalsReady,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerSingletonAsync
  /// it only registers if [_shouldRegister] returns true
  void singletonAsync<T>(
    FactoryFuncAsync<T> factoryfunc, {
    String instanceName,
    bool signalsReady,
    Iterable<Type> dependsOn,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerSingletonAsync<T>(
        factoryfunc,
        instanceName: instanceName,
        dependsOn: dependsOn,
        signalsReady: signalsReady,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerSingletonWithDependencies
  /// it only registers if [_shouldRegister] returns true
  void singletonWithDependencies<T>(
    FactoryFunc<T> factoryfunc, {
    String instanceName,
    bool signalsReady,
    Iterable<Type> dependsOn,
    Set<String> registerFor,
  }) {
    if (_shouldRegister(registerFor)) {
      getIt.registerSingletonWithDependencies<T>(
        factoryfunc,
        instanceName: instanceName,
        dependsOn: dependsOn,
        signalsReady: signalsReady,
      );
    }
  }
}
