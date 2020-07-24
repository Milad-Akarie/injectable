import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'test_injector.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  generateForDir: ['test', 'lib'],
  preferRelativeImports: false,
)
void configureTestDependencies() => $initGetIt(getIt);
