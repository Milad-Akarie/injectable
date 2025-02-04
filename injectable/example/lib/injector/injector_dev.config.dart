// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:example/module/register_module.dart' as _i3;
import 'package:example/services/abstract_service.dart' as _i4;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

const String _dev = 'dev';

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
    gh.singletonAsync<_i4.PostConstructableService>(() {
      final i = _i4.PostConstructableService(gh<_i4.IService>());
      return i.init().then((_) => i);
    });
    return this;
  }
}

class _$RegisterModule extends _i3.RegisterModule {}
