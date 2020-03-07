// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/register_module.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt g, {String environment}) {
  final registerModule = _$RegisterModule(g);
  g.registerFactory<TestSingleton2>(() => registerModule.test);
  g.registerFactoryParam<AbsService<int>, String, dynamic>(
      (url, _) => BackendService(url));
}

class _$RegisterModule extends RegisterModule {
  final GetIt _g;
  _$RegisterModule(this._g);
  @override
  TestSingleton2 get test => TestSingleton2(_g<AbsService<dynamic>>());
}
