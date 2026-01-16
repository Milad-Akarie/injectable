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

const String _platformMobile = 'platformMobile';
const String _dev = 'dev';
const String _platformWeb = 'platformWeb';

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
    gh.factory<_i978.IService>(() => _i978.ServiceImpl());
    gh.factoryCached<_i978.Model>(() => _i978.ModelX());
    gh.factory<_i978.AbstractService>(
      () => _i978.MobileService.fromService(
        gh<Set<String>>(instanceName: '__environments__'),
      ),
      registerFor: {_platformMobile},
    );
    gh.factoryParam<_i978.LoggerService, String, dynamic>(
      (name, _) => _i978.LoggerService(name),
    );
    gh.factoryAsync<_i253.Repo>(
      () => _i253.Repo.asyncRepo(gh<_i978.IService>()),
    );
    gh.singletonAsync<_i978.PostConstructableService>(() {
      final i = _i978.PostConstructableService(gh<_i978.IService>());
      return i.init().then((_) => i);
    });
    await gh.factoryAsync<_i978.AbstractService>(
      () => _i978.AsyncService.create(
        gh<Set<String>>(instanceName: '__environments__'),
      ),
      registerFor: {_dev},
      preResolve: true,
    );
    gh.lazySingletonAsync<_i253.Repo>(
      () => registerModule.getRepo(gh<_i978.IService>()),
      instanceName: 'Repo',
      dispose: _i253.disposeRepo,
    );
    gh.lazySingleton<_i978.AbstractService>(
      () => _i978.WebService(gh<Set<String>>(instanceName: '__environments__')),
      instanceName: 'WebService',
      registerFor: {_platformWeb},
    );
    gh.factoryParam<_i978.ConfigurableService, String, String>(
      (apiKey, baseUrl) =>
          _i978.ConfigurableService(apiKey: apiKey, baseUrl: baseUrl),
    );
    return this;
  }

  _i253.DisposableSingleton get disposableSingleton =>
      get<_i253.DisposableSingleton>();

  _i978.ConstService get constService => get<_i978.ConstService>();

  _i978.ServiceImpl get serviceImpl => get<_i978.ServiceImpl>();

  _i978.ModelX get modelX => get<_i978.ModelX>();

  _i978.MobileService get mobileService => get<_i978.MobileService>();

  _i978.LoggerService loggerService({required String name}) =>
      get<_i978.LoggerService>(param1: name);

  Future<_i253.Repo> get repo => getAsync<_i253.Repo>();

  Future<_i978.PostConstructableService> get postConstructableService =>
      getAsync<_i978.PostConstructableService>();

  Future<_i978.AsyncService> get asyncService => getAsync<_i978.AsyncService>();

  _i978.WebService webService({String? instanceName}) =>
      get<_i978.WebService>(instanceName: instanceName);

  _i978.ConfigurableService configurableService({
    required String apiKey,
    required String baseUrl,
  }) => get<_i978.ConfigurableService>(param1: apiKey, param2: baseUrl);
}

class _$RegisterModule extends _i253.RegisterModule {}
