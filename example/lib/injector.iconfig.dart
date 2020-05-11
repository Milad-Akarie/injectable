// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/register_module.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt g, {String environment}) {
  final registerModule = _$RegisterModule();
  g.registerFactory<LocalStorage>(() => ApiClient.named(g<String>()));
  g.registerFactoryParam<LocalStorage, String, int>(
      (url, x) => registerModule.apiClient(
            url,
            g<LocalStorage>(),
            x,
          ));
}

class _$RegisterModule extends RegisterModule {}
