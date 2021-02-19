import 'package:example/injector/Service.dart';
import 'package:example/module/register_module.dart';
import 'package:injectable/injectable.dart';

import '../lib/injector/injector.dart';

Future main(List<String> arguments) async {
  final gh = GetItHelper(getIt, null, NoEnvOrContains(platformMobile.name));
  await gh.factoryAsync<Service>(() => RepoImpl.asyncService, preResolve: true);
  // configInjector(environmentFilter: NoEnvOrContains(platformMobile.name));

  print(getIt<Service>());
}
