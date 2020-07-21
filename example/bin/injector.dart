import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

/// getIt instance that's going to
/// be used throughout the App
final GetIt getIt = GetIt.instance;

/// entry point for injection
@InjectableInit(generateForDir: ['lib', 'bin'])
void configureDependencies(String environment) {
  $initGetIt(getIt, environment: environment);
}
