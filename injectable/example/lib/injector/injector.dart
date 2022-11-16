import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

const platformMobile = Environment('platformMobile');
const platformWeb = Environment('platformWeb');

@InjectableInit(
  asExtension: false,
  initializerName: 'init',
  // ignoreUnregisteredTypes: [],
)
configInjector(
  GetIt getIt, {
  String? env,
  EnvironmentFilter? environmentFilter,
}) {
  return init(
    getIt,
    environmentFilter: environmentFilter,
    environment: env,
  );
}
