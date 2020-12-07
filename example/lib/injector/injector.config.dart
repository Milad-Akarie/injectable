// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'injection.config.micropackage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable_micropackages.dart';

import 'Service_impl.dart';
import '../services/register_module.dart';
import 'Service.dart';

/// Environment names
const _platformMobile = 'platformMobile';
const _platformWeb = 'platformWeb';
const _prod = 'prod';

/// adds generated dependencies
/// to the provided [GetIt] instance

extension GetItInjectableX on GetIt {
  GetIt init({
    String environment,
    EnvironmentFilter environmentFilter,
  }) {
    final gh = GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule(this);
    gh.factory<Service>(
        () => MobileService(get<Set<String>>(instanceName: '__environments__')),
        registerFor: {_platformMobile});
    gh.factory<Service>(
        () => WebService(get<Set<String>>(instanceName: '__environments__')),
        registerFor: {_platformWeb});
    gh.factory<Repo>(() => registerModule.repo,
        registerFor: {_prod, _platformMobile});
    MicroPackagesConfig.registerMicroModules(this);
    return this;
  }
}

class _$RegisterModule extends RegisterModule {
  final GetIt _get;
  _$RegisterModule(this._get);
  @override
  RepoImpl get repo => RepoImpl(_get<Service>());
}
