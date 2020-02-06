// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/service.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt getIt, {String environment}) {
  getIt..registerLazySingleton<ApiBloc>(() => ApiBloc.fromX(getIt<ServiceImpl2>()));
  if (environment == 'dev') {
    _registerDevDependencies(getIt);
  }
}

void _registerDevDependencies(GetIt getIt) {
  getIt..registerSingleton<MyRepository>(MyRepository(getIt<Service>()));
}
