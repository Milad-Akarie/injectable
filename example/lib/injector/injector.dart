import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

/// getIt instance that's gonna
/// be used throughout the App
final GetIt getIt = GetIt.instance;

/// entry point for injection
@InjectableInit(generateForDir: ['lib'])
void configureDependencies(String environment) {
  return $initGetIt(getIt, environment: environment);
}
