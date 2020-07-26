import 'package:injectable/injectable.dart';

import 'generic.dart';

@prod
@injectable
class Helper {
  Helper(Singleton singleton, GenericX<Singleton> generic);
}
