// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/service_b.dart';
import 'package:example/service_d.dart';
import 'package:get_it/get_it.dart';

void initGetIt(GetIt getIt, {String environment}) {
  getIt..registerFactory<Service>(() => ServiceImpl1())
    ..registerSingleton<ServiceD>(ServiceD(getIt<ServiceDD>()))
}
    ..registerFactory<ServiceDDD>(() => ServiceDDD());
  if (environment == 'production') {
    _registerProductionDependencies(getIt);
  }
}

void _registerProductionDependencies(GetIt getIt) {
  getIt..registerFactory<ServiceDD>(() => ServiceDD(getIt<ServiceDDD>()));
}
