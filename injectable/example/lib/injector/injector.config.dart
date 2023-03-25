// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: unnecessary_lambdas
// ignore_for_file: lines_longer_than_80_chars
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:awesome/awesome.module.dart' as _i6;
import 'package:awesome/calculator.dart' as _i5;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../module/register_module.dart' as _i4;
import '../services/abstract_service.dart' as _i3;

const String _dev = 'dev';
const String _platformMobile = 'platformMobile';
const String _platformWeb = 'platformWeb';
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
    final registerModule = _$RegisterModule(this);
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
    gh.singletonAsync<_i3.PostConstructableService>(() {
      final i = _i3.PostConstructableService(
        gh<_i3.IService>(),
        gh<_i5.Calculator>(),
      );
      return i.init().then((_) => i);
    });
    gh.factory<_i4.Repo>(() => registerModule.repo);
    await gh.lazySingletonAsync<_i4.Repo>(
      () => registerModule.getRepo(gh<_i3.IService>()),
      instanceName: 'Repo',
      registerFor: {_dev},
      preResolve: true,
      dispose: _i4.disposeRepo,
    );
    await _i6.AwesomePackageModule().init(gh);
    return this;
  }
}

class _$RegisterModule extends _i4.RegisterModule {
  _$RegisterModule(this._getIt);

  final _i1.GetIt _getIt;

  @override
  _i4.RepoImpl get repo => _i4.RepoImpl(_getIt<_i3.IService>());
}
