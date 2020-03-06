// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/register_module.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt g, {String environment}) {
  final registerModule = _$RegisterModule();
  g.registerFactoryParam<TestSingleton2, String, dynamic>(
      (xs, _) => registerModule.sinleton(xs));
  g.registerFactoryParam<AbsService<int>, String, dynamic>(
      (url, _) => BackendService(url),
      instanceName: 'BackendService');
}

class _$RegisterModule extends RegisterModule {}
