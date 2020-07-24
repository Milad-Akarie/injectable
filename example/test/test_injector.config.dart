// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/injector/service.dart';
import 'package:example/services/register_module.dart';
import 'package:example/services/service.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/get_it_helper.dart';

import '/example/test/sub/sub_test_service.dart';
import '/example/test/test_service.dart';

/// Environment names
const _dev = 'dev';
const _prod = 'prod';
const _test = 'test';

/// adds generated dependencies
/// to the provided [GetIt] instance

Future<void> $initGetIt(GetIt g, {String environment}) async {
  final gh = GetItHelper(g, environment);
  final registerModule = _$RegisterModule(g);
  gh.factory<Client>(() => ApiClientMock(), registerFor: {_dev});
  gh.factory<SameFolderService>(() => SameFolderService());
  gh.factoryParamAsync<Service, String, dynamic>((x, _) => DevService.init(x),
      registerFor: {_dev});
  final service = await ProdService.init();
  gh.factory<Service>(() => service, registerFor: {_prod});
  gh.factory<SubTestService>(() => SubTestService());
  gh.factory<TestService>(() => TestService());
  gh.factory<Client>(() => registerModule.client, registerFor: {_test});

  // Eager singletons must be registered in the right order
  gh.singleton<Client>(ApiClient(g<Service>()), registerFor: {_prod});
}

class _$RegisterModule extends RegisterModule {
  final GetIt _g;
  _$RegisterModule(this._g);
  @override
  ApiClient get client => ApiClient(_g<Service>());
}
