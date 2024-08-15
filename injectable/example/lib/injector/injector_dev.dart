import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector_dev.config.dart';

@InjectableInit(preferRelativeImports: false, generateForEnvironments: {dev})
configDevInjector(
  GetIt getIt, {
  String? env,
  EnvironmentFilter? environmentFilter,
}) {
  return getIt.init(
    environmentFilter: environmentFilter,
    environment: env,
  );
}
