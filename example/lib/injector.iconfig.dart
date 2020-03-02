// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:dio/dio.dart';
import 'package:example/register_module.dart';
import 'package:example/services.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt g, {String environment}) {
  final registerModule = _$RegisterModule();
  g.registerFactory<ServiceAA<Service11>>(() => registerModule.serviceA);
  g.registerFactory<ServiceX>(() => ServiceX(
        g<ServiceAA<Service11>>(),
      ));

  //Eager singletons must be registered in the right order
  g.registerSingleton<Dio>(registerModule.dioDev);
}

class _$RegisterModule extends RegisterModule {
  @override
  ServiceAA<Service11> get serviceA => ServiceAA.createService();
}
