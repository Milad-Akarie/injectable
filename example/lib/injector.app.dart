// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableAppGenerator
// **************************************************************************

import 'package:example/injector.dart';
import 'package:example/service_a.dart';
import 'package:example/service_b.dart';
import 'package:example/service_c.dart';
import 'package:example/service_d.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

class Injector extends $Injector {
  Injector.initialize() {
    $initialize();
    getIt.registerFactory(() => ServiceA());
    getIt.registerFactory(() => ServiceD());
    getIt.registerFactory(() => SerivceC());
    getIt.registerFactory(() => SerivceB(
          getIt<ServiceA>(),
          getIt<SerivceC>(),
          getIt<ServiceD>(),
        ));
  }
}
