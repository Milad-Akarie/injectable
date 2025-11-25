// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:example/module/register_module.dart' as _i253;
import 'package:example/services/abstract_service.dart' as _i978;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

const String _dev = 'dev';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i253.DisposableSingleton>(
      () => _i253.DisposableSingleton(),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i978.ConstService>(() => const _i978.ConstService());
    gh.factoryParam<_i978.IService, String?, dynamic>(
      (param, _) => _i978.ServiceImpl(param),
      registerFor: {_dev},
    );
    gh.factory<_i978.Model>(() => _i978.ModelX());
    await gh.factoryAsync<_i978.AbstractService>(
      () => _i978.AsyncService.create(
        gh<Set<String>>(instanceName: '__environments__'),
      ),
      registerFor: {_dev},
      preResolve: true,
    );
    gh.lazySingletonAsync<_i253.Repo>(
      () => registerModule.getRepo(
        gh<_i978.IService>(instanceName: 'ServiceImpl'),
      ),
      instanceName: 'Repo',
      registerFor: {_dev},
      dispose: _i253.disposeRepo,
    );
    gh.singletonAsync<_i978.PostConstructableService>(() {
      final i = _i978.PostConstructableService(gh<_i978.IService>());
      return i.init().then((_) => i);
    });
    return this;
  }
}

class _$RegisterModule extends _i253.RegisterModule {}
