// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:awesome/awesome.module.dart' as _i3;
import 'package:example/module/register_module.dart' as _i5;
import 'package:example/services/abstract_service.dart' as _i4;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

const String _dev = 'dev';
const String _platformMobile = 'platformMobile';
const String _platformWeb = 'platformWeb';
const String _test = 'test';

/// ignore_for_file: unnecessary_lambdas
/// ignore_for_file: lines_longer_than_80_chars
extension GetItInjectableX on _i1.GetIt {
  /// initializes the registration of main-scope dependencies inside of [GetIt]
  Future<_i1.GetIt> init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    await _i3.AwesomePackageModule().init(gh);
    final registerModule = _$RegisterModule(this);
    gh.factory<_i4.AbstractService>(
      () => _i4.MobileService.fromService(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_platformMobile},
    );
    gh.lazySingleton<_i4.AbstractService>(
      () => _i4.WebService(gh<Set<String>>(instanceName: '__environments__')),
      instanceName: 'WebService',
      registerFor: {_platformWeb},
    );
    await gh.factoryAsync<_i4.AbstractService>(
      () => _i4.AsyncService.create(
          gh<Set<String>>(instanceName: '__environments__')),
      registerFor: {_dev},
      preResolve: true,
    );
    gh.singleton<_i5.DisposableSingleton>(
      _i5.DisposableSingleton(),
      dispose: (i) => i.dispose(),
    );
    gh.factoryParam<_i4.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i4.ServiceImpl(param),
      registerFor: {_dev},
    );
    gh.factoryParamAsync<_i4.IService, String?, dynamic>(
      (
        param,
        _,
      ) =>
          _i4.LazyServiceImpl.create(param),
      registerFor: {_test},
    );
    gh.singletonAsync<_i4.PostConstructableService>(() {
      final i = _i4.PostConstructableService(gh<_i4.IService>());
      return i.init().then((_) => i);
    });
    gh.factory<_i5.Repo>(() => registerModule.repo);
    await gh.lazySingletonAsync<_i5.Repo>(
      () => registerModule.getRepo(gh<_i4.IService>()),
      instanceName: 'Repo',
      registerFor: {_dev},
      preResolve: true,
      dispose: _i5.disposeRepo,
    );
    return this;
  }
}

class _$RegisterModule extends _i5.RegisterModule {
  _$RegisterModule(this._getIt);

  final _i1.GetIt _getIt;

  @override
  _i5.RepoImpl get repo => _i5.RepoImpl(_getIt<_i4.IService>());
}
