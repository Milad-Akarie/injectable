import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.iconfig.dart';


final getIt = GetIt.instance;

@InjectableInit(generateForDir: ['lib'])
void configureDependencies() => $initGetIt(getIt, environment: Environment.dev);
