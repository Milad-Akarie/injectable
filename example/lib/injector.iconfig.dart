// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/services/service.dart';
import 'package:example/services/register_module.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt g, {String environment}) {
  final registerModule = _$RegisterModule();
  g.registerFactoryAsync<Service>(() => DemoService.init());
  g.registerFactoryParam<Client, String, dynamic>(
          (url, _) => registerModule.apiClient(url));
  g.registerFactory<Client>(
          () => ApiClient(g<String>(instanceName: 'baseUrl')));

  //Register dev Dependencies --------
  if (environment == 'dev') {
    g.registerFactory<String>(() => registerModule.devUrl,
        instanceName: 'baseUrl');
  }

  //Register prod Dependencies --------
  if (environment == 'prod') {
    g.registerFactory<String>(() => registerModule.prodUrl,
        instanceName: 'baseUrl');
  }
}

class _$RegisterModule extends RegisterModule {}
