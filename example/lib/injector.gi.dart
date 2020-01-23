// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectorGenerator
// **************************************************************************

import 'package:example/service_x.dart';
import 'package:example/service_y.dart';
import 'package:example/service_cc.dart';
import 'package:example/service_b.dart';
import 'package:example/service_d.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;
void $configure() {
  getIt.registerSingleton(ServiceX());
  getIt.registerFactory(() => ServiceY());
  getIt.registerLazySingleton(() => SerivceCC());

  getIt.registerFactory<AbstractClass>(() => AbstractClassImpl(),
      instanceName: 'impl1');
  getIt.registerFactory<AbstractClass>(() => AbstractClassImpl(),
      instanceName: 'impl2');
  getIt.registerFactory<AbstractClass>(() => AbstractClassImpl(),
      instanceName: 'impl3');

  getIt('impl1');

  getIt.registerFactory(() => MyBloc(getIt<AbstractClass>('mock1')));
}
