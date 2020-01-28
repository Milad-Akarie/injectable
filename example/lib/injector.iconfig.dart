// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;
void $initGetIt({String environment}) {
  getIt
    ..registerFactory<Service>(() => ServiceImpl1(),
        instanceName: 'ServiceImpl1')
    ..registerFactory<Service>(() => ServiceImpl2(),
        instanceName: 'ServiceImpl2')
    ..registerFactory<MyRepository>(() => MyRepository(getIt('ServiceImpl1')));
}
