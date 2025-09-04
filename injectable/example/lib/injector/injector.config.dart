// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../module/register_module.dart' as _i995;
import '../services/abstract_service.dart' as _i889;

const String _test = 'test';
const String _dev = 'dev';
const String _platformWeb = 'platformWeb';
const String _platformMobile = 'platformMobile';

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.singleton<_i995.DisposableSingleton>(
      () => _i995.DisposableSingleton(),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i889.ConstService>(() => const _i889.ConstService());
    gh.lazySingleton<_i889.ModelC>(() => _i889.ModelC.from());
    gh.lazySingleton<_i889.ModelW>(() => _i889.ModelW.from(gh<String>()));
    gh.factoryParamAsync<_i889.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i889.LazyServiceImpl.create(param),
      registerFor: {_test},
    );
    gh.factoryParam<_i889.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i889.ServiceImpl.new(param),
      instanceName: 'ServiceImpl',
      registerFor: {_dev},
    );
    gh.factory<_i889.Model>(() => _i889.ModelX());
    await gh.factoryAsync<_i889.AbstractService>(
      () => _i889.AsyncService.create(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_dev},
      preResolve: true,
    );
    gh.lazySingleton<_i889.ModelZ>(() => _i889.ModelZ.from(gh<_i889.ModelW>()));
    gh.lazySingletonAsync<_i995.Repo>(
      () => registerModule
          .getRepo(gh<_i889.IService>(instanceName: 'ServiceImpl')),
      instanceName: 'Repo',
      registerFor: {_dev},
      dispose: _i995.disposeRepo,
    );
    gh.lazySingleton<_i889.AbstractService>(
      () => _i889.WebService.new(
          gh<Set<String>>(instanceName: '__environments__')),
      instanceName: 'WebService',
      registerFor: {_platformWeb},
    );
    gh.singletonAsync<_i889.PostConstructableService>(() async {
      final i =
          _i889.PostConstructableService.new(await getAsync<_i889.IService>());
      return i.init().then((_) => i);
    });
    gh.factory<_i889.AbstractService>(
      () => _i889.MobileService.fromService(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_platformMobile},
    );
    return this;
  }
}

class _$RegisterModule extends _i995.RegisterModule {}
