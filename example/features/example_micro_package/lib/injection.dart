import 'package:get_it/get_it.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;
@InjectableInit(
  asExtension: true
)
void configureInjection(){
  // This extension method is created for us the first time the generator is executed
  getIt.$initGetIt();
}