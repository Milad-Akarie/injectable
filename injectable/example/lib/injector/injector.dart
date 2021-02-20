import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

const platformMobile = Environment('platformMobile');
const platformWeb = Environment('platformWeb');

@InjectableInit(
  initializerName: 'init',
  asExtension: true,
  usesNullSafety: false,
)
configInjector(
  GetIt getIt, {
  String env,
  EnvironmentFilter environmentFilter,
}) {
  return getIt.init(
    environmentFilter: environmentFilter,
    environment: env,
  );
}
