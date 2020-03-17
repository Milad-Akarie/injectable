// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/register_module.dart';
import 'package:get_it/get_it.dart';

Future<void> $initGetIt(GetIt g, {String environment}) async {
  final registerModule = _$RegisterModule(g);
  final apiClient = await registerModule.futureSing;
  g.registerFactory<ApiClient>(() => apiClient, instanceName: 'nasf23m22e');
  final apiClient1 = await registerModule.futureSingr;
  g.registerFactory<ApiClient>(() => apiClient1);
  g.registerFactory<TestSingleton2>(() => registerModule.test);
  g.registerFactoryParam<AbsService<int>, String, dynamic>(
      (url, _) => BackendService(url));
  final apiClient2 = await ApiClient.create(g<AbsService<dynamic>>());
  g.registerFactory<ApiClient>(() => apiClient2);
}

class _$RegisterModule extends RegisterModule {
  final GetIt _g;
  _$RegisterModule(this._g);
  @override
  TestSingleton2 get test => TestSingleton2(_g<AbsService<dynamic>>());
}
