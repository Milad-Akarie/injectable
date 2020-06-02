// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/services/register_module.dart';
import 'package:example/services/service.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt g, {String environment}) {
  final registerModule = _$RegisterModule();
  g.registerFactoryParam<Client, String, dynamic>(
      (url, _) => registerModule.apiClient(url));
  g.registerFactory<Client>(
      () => ApiClient(g<String>(instanceName: 'baseUrl')));
  g.registerFactoryAsync<Service>(() => DemoService.init());
}

class _$RegisterModule extends RegisterModule {}
