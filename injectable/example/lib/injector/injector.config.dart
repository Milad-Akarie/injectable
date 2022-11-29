// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:awesome/awesome.module.dart' as _i4;
import 'package:example/services/abstract_service.dart' as _i3;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

const String _platformMobile = 'platformMobile';

/// ignore_for_file: unnecessary_lambdas
/// ignore_for_file: lines_longer_than_80_chars
extension GetItInjectableX on _i1.GetIt {
  /// initializes the registration of main-scope dependencies inside of [GetIt]
  Future<_i1.GetIt> init(
      {String? environment, _i2.EnvironmentFilter? environmentFilter}) async {
    final gh = _i2.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i3.AbstractService>(
        () => _i3.MobileService.fromService(
            gh<Set<String>>(instanceName: '__environments__')),
        registerFor: {_platformMobile});
    await _i4.AwesomePackageModule().init(gh);
    return this;
  }

  /// initializes the registration of auth-scope dependencies inside of [GetIt]
  _i1.GetIt initAuthScope({_i1.ScopeDisposeFunc? dispose}) {
    return _i2.GetItHelper(this).initScope('auth', dispose: dispose,
        init: (_i2.GetItHelper gh) {
      gh.singletonAsync<_i3.PostConstructableService>(() {
        final i = _i3.PostConstructableService(gh<_i3.IService>());
        return i.init().then((_) => i);
      });
    });
  }
}
