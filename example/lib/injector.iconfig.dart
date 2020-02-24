// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/services.dart';
import 'package:dio/dio.dart';
import 'package:example/register_module.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

Future<void> $initGetIt(GetIt g, {String environment}) async {
  final registerModule = _$RegisterModule(g);
  g.registerFactory<Service11>(() => Service11());
  g.registerFactory<ServiceAbs>(() => registerModule.serviceAA);

  //Register dev Dependencies --------
  if (environment == 'dev') {
    final sharedPreferences = await registerModule.prefs;
    g.registerFactory<SharedPreferences>(() => sharedPreferences);
  }

  //Eager singletons must be registered in the right order
  g.registerSingleton<Dio>(registerModule.dioDev);
}

class _$RegisterModule extends RegisterModule {
  final GetIt _g;
  _$RegisterModule(this._g);
  ServiceAA get serviceAA => ServiceAA(
        _g<FirebaseAuth>(),
        _g<Dio>(),
      );
}
