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

import '../features/demo_lazy_view_model/view_model/lazy_view_model.dart'
    as _i4;
import '../features/demo_view_model/view_model/view_model.dart' as _i5;
import '../services/abstract_service.dart' as _i3;

const String _platformMobile = 'platformMobile';
const String _platformWeb = 'platformWeb';
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
    gh.factory<_i4.DemoLazyViewModel>(() => _i4.DemoLazyViewModel());
    gh.singleton<_i5.DemoViewModel>(_i5.DemoViewModel());
    gh.factory<_i3.Model>(() => _i3.ModelX());
    return this;
  }
}
