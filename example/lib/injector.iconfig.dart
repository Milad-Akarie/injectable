// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:shared_preferences/shared_preferences.dart';
import 'package:example/register_module.dart';
import 'package:get_it/get_it.dart';

Future<void> $initGetIt(GetIt g, {String environment}) async {
  final registerModule = _$RegisterModule();
  final sharedPreferences = await registerModule.prefs;
  g.registerFactory<SharedPreferences>(() => sharedPreferences);
  g.registerFactoryParam<BackendService, String, dynamic>(
      (url, _) => registerModule.getService(url));
  g.registerFactoryAsync<ApiClient>(() => ApiClient.create());
}

class _$RegisterModule extends RegisterModule {}
