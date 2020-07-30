import 'package:example/injector/injector.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

GetIt getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
void configInjector() {
  $initGetIt(getIt);
}
