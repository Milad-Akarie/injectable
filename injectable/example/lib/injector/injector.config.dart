// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: unnecessary_lambdas
// ignore_for_file: lines_longer_than_80_chars
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../module/register_module.dart' as _i4;
import '../services/abstract_service.dart' as _i3;

const String _platformMobile = 'platformMobile';
const String _platformWeb = 'platformWeb';
const String _dev = 'dev';
const String _test = 'test';

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
    gh.factory<_i3.AbstractService>(
      () => _i3.MobileService.fromService(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_platformMobile},
    );
    gh.lazySingleton<_i3.AbstractService>(
      () => _i3.WebService(gh<Set<String>>(instanceName: '__environments__')),
      instanceName: 'WebService',
      registerFor: {_platformWeb},
    );
    await gh.factoryAsync<_i3.AbstractService>(
      () => _i3.AsyncService.create(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_dev},
      preResolve: true,
    );
    gh.factory<_i3.ConstService>(() => const _i3.ConstService());
    gh.factory<_i3.ConstViewModel>(() => const _i3.ConstViewModel());
    gh.singleton<_i4.DisposableSingleton>(
      _i4.DisposableSingleton(),
      dispose: (i) => i.dispose(),
    );
    gh.factoryParam<_i3.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i3.ServiceImpl(param),
      instanceName: 'ServiceImpl',
      registerFor: {_dev},
    );
    gh.factoryParamAsync<_i3.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i3.LazyServiceImpl.create(param),
      registerFor: {_test},
    );
    gh.factory<_i3.Model>(() => _i3.ModelX());
    gh.singletonAsync<_i3.PostConstructableService>(() async {
      final i = _i3.PostConstructableService(await getAsync<_i3.IService>());
      return i.init().then((_) => i);
    });
    gh.lazySingletonAsync<_i4.Repo>(
      () =>
          registerModule.getRepo(gh<_i3.IService>(instanceName: 'ServiceImpl')),
      instanceName: 'Repo',
      registerFor: {_dev},
      dispose: _i4.disposeRepo,
    );
    gh.lazySingleton<_i3.ViewModel1>(() => _i3.ViewModel1());
    gh.singleton<_i3.ViewModel2>(_i3.ViewModel2());
    return this;
  }
}

class _$RegisterModule extends _i4.RegisterModule {}
