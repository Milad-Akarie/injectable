@packageDependenciesLoader
library;

import 'package:bootstrap/src/bootstrap_class.dart';
import 'package:injectable/injectable.dart';

@InjectableInit.microPackage()

/// MicroPackages are sub packages that can be depended on and used by the root
/// package.
///
/// Packages annotated as micro will generate a MicroPackageModule
/// instead of an init-method and the initiation of those modules is done
/// automatically by the root package's init-method.
void initMicroPackage() {}

/// To Register third party types, add your third party types as property
/// accessors or methods as follows:
@module
abstract class RegisterModule {
  @singleton
  BootstrapClass get bootstrapClass => BootstrapClass();
}
