import 'package:injectable/injectable.dart';

import 'injector.iconfig.dart';

@injectableInit
void configure() => $initGetIt();
