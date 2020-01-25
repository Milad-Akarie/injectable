import 'package:get_it/get_it.dart';
import 'package:injectable/injectable_annotations.dart';

import 'injector.iconfig.dart';

GetIt getIt = GetIt.instance;

@injectIt
void configure() => initGetIt(
      getIt,
      environment: Environment.development,
    );
