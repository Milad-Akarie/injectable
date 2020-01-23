import 'package:injectable/injectable_annotations.dart';

import 'injector.gi.dart';

@injectorConfig
@Injectable.factory(STring)
void configure() {
  getIt.registerFactory(func);
  $configure();
}
