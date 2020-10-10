import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

const platformMobile = Environment("platformMobile");
const platformWeb = Environment("platformWeb");

GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configInjector({String env, EnvironmentFilter environmentFilter}) {
  getIt.init(environmentFilter: environmentFilter);
}
