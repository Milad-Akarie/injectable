// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:dio/dio.dart';
import 'package:example/register_module.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

Future<void> $initGetIt(GetIt g, {String environment}) async {
  final registerModule = _$RegisterModule(g);

  //Register prod Dependencies --------
  if (environment == 'prod') {
    g.registerFactory<ServiceAA>(() => registerModule.service);
  }

  //Register dev Dependencies --------
  if (environment == 'dev') {
    final sharedPreferences = await registerModule.prefs;
    g.registerFactory<SharedPreferences>(() => sharedPreferences);
  }

//  Eager singletons must be registered in the right order
  if (environment == 'dev') {
    g.registerSingleton<Dio>(registerModule.dioDev);
  }
}

class _$RegisterModule extends RegisterModule {
  final GetIt g;
  _$RegisterModule(this.g);
  ServiceAA get service => ServiceAA();
}
