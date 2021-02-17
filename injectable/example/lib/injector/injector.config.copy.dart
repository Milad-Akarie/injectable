// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'Service_impl.dart';
import '../services/register_module.dart';
import 'Service.dart';

/// Environment names
const _prod = 'prod';
const _platformMobile = 'platformMobile';
const _platformWeb = 'platformWeb';

/// adds generated dependencies
/// to the provided [GetIt] instance

extension GetItInjectableX on GetIt {
  Future<GetIt> init({
    String environment,
    EnvironmentFilter environmentFilter,
  }) async {
    final gh = GetItHelper(this, environment, environmentFilter);

    final registerModule = _$RegisterModule(this);
    // final resolvedService = await registerModule.resolvedService;
    // gh.factory<Service>(() => resolvedService, registerFor: {_prod});
    await gh.factoryAsync<Service>(() => registerModule.resolvedService, registerFor: {_prod});
    gh.factory<Service>(() => MobileService(get<Set<String>>(instanceName: '__environments__')),
        registerFor: {_platformMobile});
    gh.factory<Service>(() => WebService(get<Set<String>>(instanceName: '__environments__')),
        registerFor: {_platformWeb});
    final resolvedInt = await registerModule.asyncValue;
    gh.factory<int>(() => resolvedInt);
    gh.factory<Repo>(() => registerModule.repo, registerFor: {_prod, _platformMobile});
    return this;
  }
}

class _$RegisterModule extends RegisterModule {
  final GetIt _get;
  _$RegisterModule(this._get);
  @override
  RepoImpl get repo => RepoImpl(_get<Service>());
}
