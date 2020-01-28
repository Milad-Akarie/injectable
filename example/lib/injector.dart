import 'package:injectable/injectable_annotations.dart';

import 'injector.iconfig.dart';

@injectableInit
void configure() => $initGetIt();
