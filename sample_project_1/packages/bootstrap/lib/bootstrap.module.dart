//@GeneratedMicroModule;BootstrapPackageModule;package:bootstrap/bootstrap.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:a/src/data_service.dart' as _i193;
import 'package:b/src/sample_service.dart' as _i539;
import 'package:bootstrap/bootstrap.dart' as _i858;
import 'package:bootstrap/src/bootstrap_class.dart' as _i481;
import 'package:injectable/injectable.dart' as _i526;

class BootstrapPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final registerModule = _$RegisterModule();
    gh.singleton<_i539.SampleService>(() => _i539.SampleService());
    gh.singleton<_i481.BootstrapClass>(() => registerModule.bootstrapClass);
    gh.singleton<_i539.DataServiceInterface>(
        () => _i193.DataService(gh<_i539.SampleService>()));
    gh.singleton<_i539.InterfaceConsumingClass>(
        () => _i539.InterfaceConsumingClass(gh<_i539.DataServiceInterface>()));
  }
}

class _$RegisterModule extends _i858.RegisterModule {}
