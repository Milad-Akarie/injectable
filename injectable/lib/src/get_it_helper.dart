import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// a helper class to handle conditional registering
class GetItHelper {
  /// passed getIt instance
  final GetIt getIt;

  /// filter for whether to register for the given set of environments
  final EnvironmentFilter _environmentFilter;

  /// creates a new instance of GetItHelper
  GetItHelper(this.getIt,
      [String? environment, EnvironmentFilter? environmentFilter])
      : assert(environmentFilter == null || environment == null),
        _environmentFilter = environmentFilter ?? NoEnvOrContains(environment) {
    // register current Environments as lazy singleton
    if (!getIt.isRegistered<Set<String>>(instanceName: kEnvironmentsName)) {
      getIt.registerLazySingleton<Set<String>>(
        () => _environmentFilter.environments,
        instanceName: kEnvironmentsName,
      );
    }
  }

  bool _canRegister(Set<String>? registerFor) {
    return _environmentFilter.canRegister(registerFor ?? {});
  }

  /// a conditional wrapper method for getIt.registerFactory
  /// it only registers if [_canRegister] returns true
  void factory<T extends Object>(
    FactoryFunc<T> factoryfunc, {
    String? instanceName,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerFactory<T>(
        factoryfunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerFactoryAsync
  /// it only registers if [_canRegister] returns true
  Future<void> factoryAsync<T extends Object>(
    FactoryFuncAsync<T> factoryfunc, {
    String? instanceName,
    bool preResolve = false,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      if (preResolve) {
        return factoryfunc().then(
          (instance) => factory(
            () => instance,
            instanceName: instanceName,
          ),
        );
      } else {
        getIt.registerFactoryAsync<T>(
          factoryfunc,
          instanceName: instanceName,
        );
      }
    }
    return Future.value(null);
  }

  /// a conditional wrapper method for getIt.registerFactoryParam
  /// it only registers if [_canRegister] returns true
  void factoryParam<T extends Object, P1, P2>(
    FactoryFuncParam<T, P1, P2> factoryfunc, {
    String? instanceName,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerFactoryParam<T, P1, P2>(
        factoryfunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerFactoryParamAsync
  /// it only registers if [_canRegister] returns true
  void factoryParamAsync<T extends Object, P1, P2>(
    FactoryFuncParamAsync<T, P1?, P2?> factoryfunc, {
    String? instanceName,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerFactoryParamAsync<T, P1, P2>(
        factoryfunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerLazySingleton
  /// it only registers if [_canRegister] returns true
  void lazySingleton<T extends Object>(
    FactoryFunc<T> factoryfunc, {
    String? instanceName,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerLazySingleton<T>(
        factoryfunc,
        instanceName: instanceName,
        dispose: dispose,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerLazySingletonAsync
  /// it only registers if [_canRegister] returns true
  Future<void> lazySingletonAsync<T extends Object>(
    FactoryFuncAsync<T> factoryfunc, {
    String? instanceName,
    bool preResolve = false,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      if (preResolve) {
        return factoryfunc().then(
          (instance) => lazySingleton(
            () => instance,
            instanceName: instanceName,
            dispose: dispose,
          ),
        );
      } else {
        getIt.registerLazySingletonAsync<T>(
          factoryfunc,
          instanceName: instanceName,
          dispose: dispose,
        );
      }
    }
    return Future.value(null);
  }

  /// a conditional wrapper method for getIt.registerSingleton
  /// it only registers if [_canRegister] returns true
  void singleton<T extends Object>(
    T instance, {
    String? instanceName,
    bool? signalsReady,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerSingleton<T>(
        instance,
        instanceName: instanceName,
        signalsReady: signalsReady,
        dispose: dispose,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerSingletonAsync
  /// it only registers if [_canRegister] returns true
  Future<void> singletonAsync<T extends Object>(
    FactoryFuncAsync<T> factoryfunc, {
    String? instanceName,
    bool? signalsReady,
    bool preResolve = false,
    Iterable<Type>? dependsOn,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      if (preResolve) {
        return factoryfunc().then(
          (instance) => singleton(
            instance,
            instanceName: instanceName,
            signalsReady: signalsReady,
            dispose: dispose,
          ),
        );
      } else {
        getIt.registerSingletonAsync<T>(
          factoryfunc,
          instanceName: instanceName,
          dependsOn: dependsOn,
          signalsReady: signalsReady,
          dispose: dispose,
        );
      }
    }
    return Future.value(null);
  }

  /// a conditional wrapper method for getIt.registerSingletonWithDependencies
  /// it only registers if [_canRegister] returns true
  void singletonWithDependencies<T extends Object>(
    FactoryFunc<T> factoryfunc, {
    String? instanceName,
    bool? signalsReady,
    Iterable<Type>? dependsOn,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerSingletonWithDependencies<T>(
        factoryfunc,
        instanceName: instanceName,
        dependsOn: dependsOn,
        signalsReady: signalsReady,
        dispose: dispose,
      );
    }
  }
}
