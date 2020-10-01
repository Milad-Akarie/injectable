import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

const platformMobile = Environment("platformMobile");
const platformWeb = Environment("platformWeb");

GetIt getIt = GetIt.instance;

@MicroPackageRootInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: true,
)
void configInjector({String env, EnvironmentFilter environmentFilter}) {
  getIt.$initGetIt(environmentFilter: environmentFilter);
}
