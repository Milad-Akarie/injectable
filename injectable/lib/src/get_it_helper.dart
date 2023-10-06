import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// a helper class to handle conditional registering
class GetItHelper {
  /// passed getIt instance
  final GetIt getIt;

  /// filter for whether to register for the given set of environments
  late final EnvironmentFilter _environmentFilter;

  /// creates a new instance of GetItHelper
  GetItHelper(this.getIt,
      [String? environment, EnvironmentFilter? environmentFilter])
      : assert(environmentFilter == null || environment == null) {
    // register current EnvironmentsFilter as lazy singleton
    if (!getIt.isRegistered<EnvironmentFilter>(
        instanceName: kEnvironmentsFilterName)) {
      _environmentFilter = environmentFilter ?? NoEnvOrContains(environment);
      getIt.registerLazySingleton<EnvironmentFilter>(
        () => _environmentFilter,
        instanceName: kEnvironmentsFilterName,
      );
    } else {
      _environmentFilter =
          getIt<EnvironmentFilter>(instanceName: kEnvironmentsFilterName);
    }

    // register current Environments as lazy singleton
    if (!getIt.isRegistered<Set<String>>(instanceName: kEnvironmentsName)) {
      getIt.registerLazySingleton<Set<String>>(
        () => _environmentFilter.environments,
        instanceName: kEnvironmentsName,
      );
    }
  }

  T call<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) =>
      getIt.get<T>(
        instanceName: instanceName,
        param1: param1,
        param2: param2,
      );

  Future<T> getAsync<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) =>
      getIt.getAsync<T>(
        instanceName: instanceName,
        param1: param1,
        param2: param2,
      );

  bool _canRegister(Set<String>? registerFor) {
    return _environmentFilter.canRegister(registerFor ?? {});
  }

  /// a conditional wrapper method for getIt.registerFactory
  /// it only registers if [_canRegister] returns true
  void factory<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerFactory<T>(
        factoryFunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerFactoryAsync
  /// it only registers if [_canRegister] returns true
  Future<void> factoryAsync<T extends Object>(
    FactoryFuncAsync<T> factoryFunc, {
    String? instanceName,
    bool preResolve = false,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      if (preResolve) {
        return factoryFunc().then(
          (instance) => factory(
            () => instance,
            instanceName: instanceName,
            registerFor: registerFor,
          ),
        );
      } else {
        getIt.registerFactoryAsync<T>(
          factoryFunc,
          instanceName: instanceName,
        );
      }
    }
    return Future.value(null);
  }

  /// a conditional wrapper method for getIt.registerFactoryParam
  /// it only registers if [_canRegister] returns true
  void factoryParam<T extends Object, P1, P2>(
    FactoryFuncParam<T, P1, P2> factoryFunc, {
    String? instanceName,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerFactoryParam<T, P1, P2>(
        factoryFunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerFactoryParamAsync
  /// it only registers if [_canRegister] returns true
  void factoryParamAsync<T extends Object, P1, P2>(
    FactoryFuncParamAsync<T, P1?, P2?> factoryFunc, {
    String? instanceName,
    Set<String>? registerFor,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerFactoryParamAsync<T, P1, P2>(
        factoryFunc,
        instanceName: instanceName,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerLazySingleton
  /// it only registers if [_canRegister] returns true
  void lazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerLazySingleton<T>(
        factoryFunc,
        instanceName: instanceName,
        dispose: dispose,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerLazySingletonAsync
  /// it only registers if [_canRegister] returns true
  Future<void> lazySingletonAsync<T extends Object>(
    FactoryFuncAsync<T> factoryFunc, {
    String? instanceName,
    bool preResolve = false,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      if (preResolve) {
        return factoryFunc().then(
          (instance) => lazySingleton(
            () => instance,
            instanceName: instanceName,
            registerFor: registerFor,
            dispose: dispose,
          ),
        );
      } else {
        getIt.registerLazySingletonAsync<T>(
          factoryFunc,
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
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    bool? signalsReady,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerSingleton<T>(
        factoryFunc(),
        instanceName: instanceName,
        signalsReady: signalsReady,
        dispose: dispose,
      );
    }
  }

  /// a conditional wrapper method for getIt.registerSingletonAsync
  /// it only registers if [_canRegister] returns true
  Future<void> singletonAsync<T extends Object>(
    FactoryFuncAsync<T> factoryFunc, {
    String? instanceName,
    bool? signalsReady,
    bool preResolve = false,
    Iterable<Type>? dependsOn,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      if (preResolve) {
        return factoryFunc().then(
          (instance) => singleton(
            () => instance,
            instanceName: instanceName,
            signalsReady: signalsReady,
            registerFor: registerFor,
            dispose: dispose,
          ),
        );
      } else {
        getIt.registerSingletonAsync<T>(
          factoryFunc,
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
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    bool? signalsReady,
    Iterable<Type>? dependsOn,
    Set<String>? registerFor,
    DisposingFunc<T>? dispose,
  }) {
    if (_canRegister(registerFor)) {
      getIt.registerSingletonWithDependencies<T>(
        factoryFunc,
        instanceName: instanceName,
        dependsOn: dependsOn,
        signalsReady: signalsReady,
        dispose: dispose,
      );
    }
  }

  /// a helper method to push a new scope and init it's dependencies
  /// asynchronously inside of [GetIt]
  Future<GetIt> initScopeAsync(String name,
      {required Future<void> Function(GetItHelper gh) init,
      ScopeDisposeFunc? dispose}) {
    final completer = Completer<GetIt>();
    getIt.pushNewScope(
      scopeName: name,
      init: (getIt) async {
        await init(this);
        completer.complete(getIt);
      },
      dispose: dispose,
    );
    return completer.future;
  }

  /// a helper method to push a new scope and init it's dependencies
  /// inside of [GetIt]
  GetIt initScope(String name,
      {required void Function(GetItHelper gh) init,
      ScopeDisposeFunc? dispose}) {
    getIt.pushNewScope(
      scopeName: name,
      init: (_) => init(this),
      dispose: dispose,
    );
    return getIt;
  }
}
