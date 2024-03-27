// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../module/register_module.dart' as _i3;
import '../services/abstract_service.dart' as _i4;

const String _test = 'test';
const String _dev = 'dev';
const String _platformWeb = 'platformWeb';
const String _platformMobile = 'platformMobile';

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i1.GetIt> init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.singleton<_i3.DisposableSingleton>(
      () => _i3.DisposableSingleton(),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i4.ConstService>(() => const _i4.ConstService());
    gh.factoryParamAsync<_i4.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i4.LazyServiceImpl.create(param),
      registerFor: {_test},
    );
    gh.factoryParam<_i4.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i4.ServiceImpl(param),
      instanceName: 'ServiceImpl',
      registerFor: {_dev},
    );
    gh.factory<_i4.Model>(() => _i4.ModelX());
    await gh.factoryAsync<_i4.AbstractService>(
      () => _i4.AsyncService.create(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_dev},
      preResolve: true,
    );
    gh.lazySingletonAsync<_i3.Repo>(
      () =>
          registerModule.getRepo(gh<_i4.IService>(instanceName: 'ServiceImpl')),
      instanceName: 'Repo',
      registerFor: {_dev},
      dispose: _i3.disposeRepo,
    );
    gh.lazySingleton<_i4.AbstractService>(
      () => _i4.WebService(gh<Set<String>>(instanceName: '__environments__')),
      instanceName: 'WebService',
      registerFor: {_platformWeb},
    );
    gh.singletonAsync<_i4.PostConstructableService>(() async {
      final i = _i4.PostConstructableService(await getAsync<_i4.IService>());
      return i.init().then((_) => i);
    });
    gh.factory<_i4.AbstractService>(
      () => _i4.MobileService.fromService(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_platformMobile},
    );
    return this;
  }
}

class _$RegisterModule extends _i3.RegisterModule {}
