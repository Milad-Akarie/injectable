// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../module/register_module.dart' as _i4;
import '../services/abstract_service.dart' as _i3;
import 'injector.dart' as _i5;

const String _platformMobile = 'platformMobile';
const String _platformWeb = 'platformWeb';
const String _dev = 'dev';
const String _test = 'test';
const String _prod = 'prod';

// ignore_for_file: unnecessary_lambdas
// ignore_for_file: lines_longer_than_80_chars
/// an extension to register the provided dependencies inside of [GetIt]
extension GetItInjectableX on _i1.GetIt {
  /// initializes the registration of provided dependencies inside of [GetIt]
  Future<_i1.GetIt> init(
      {String? environment, _i2.EnvironmentFilter? environmentFilter}) async {
    final gh = _i2.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule(this);
    gh.factory<_i3.AbstractService>(
        () => _i3.MobileService.fromService(
            get<Set<String>>(instanceName: '__environments__')),
        registerFor: {_platformMobile});
    gh.lazySingleton<_i3.AbstractService>(
        () =>
            _i3.WebService(get<Set<String>>(instanceName: '__environments__')),
        instanceName: 'WebService',
        registerFor: {_platformWeb});
    await gh.factoryAsync<_i3.AbstractService>(
        () => _i3.AsyncService.create(
            get<Set<String>>(instanceName: '__environments__')),
        registerFor: {_dev},
        preResolve: true);
    gh.factoryParam<_i3.IService, String?, dynamic>(
        (param, _) => _i3.ServiceImpl(param),
        registerFor: {_dev});
    gh.factoryParamAsync<_i3.IService, String?, dynamic>(
        (param, _) => _i3.LazyServiceImpl.create(param),
        registerFor: {_test});
    gh.factory<_i4.Repo>(() => registerModule.repo,
        registerFor: {_prod, _platformMobile});
    await gh.lazySingletonAsync<_i4.Repo>(
        () => registerModule.getRepo(get<_i3.IService>()),
        instanceName: 'Repo',
        registerFor: {_dev},
        preResolve: true,
        dispose: _i4.disposeRepo);
    gh.factory<_i5.ServiceB>(() => _i5.ServiceB(get<_i5.ServiceA>()));
    gh.singleton<_i4.DisposableSingleton>(_i4.DisposableSingleton(),
        dispose: (i) => i.dispose());
    return this;
  }
}

class _$RegisterModule extends _i4.RegisterModule {
  _$RegisterModule(this._getIt);

  final _i1.GetIt _getIt;

  @override
  _i4.RepoImpl get repo => _i4.RepoImpl(_getIt<_i3.IService>());
}
