import 'package:get_it/get_it.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';

import 'injector.config.dart';

const platformMobile = Environment("platformMobile");
const platformWeb = Environment("platformWeb");

GetIt getIt = GetIt.instance;


/// Micropackages root init should be used when the project uses
/// a micro package folder structure
/// If this is not the case, then fallback to InjectableInit annotation.
/// MicroPackageRootInit assumes that a folder named features exist and that is
/// the place where you place your micro packages projects
@MicroPackageRootInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configInjector({String? env, EnvironmentFilter? environmentFilter}) {
  getIt.init(environmentFilter: environmentFilter);
}
