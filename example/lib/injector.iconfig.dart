// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:example/register_module.dart';
import 'package:get_it/get_it.dart';

void $initGetIt(GetIt g, {String environment}) {
  g.registerSingletonAsync<ServiceAA>(
      () => ServiceAA.createService(
            g<String>(),
          ),
      dependsOn: [String]);
}
