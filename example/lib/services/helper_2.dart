import 'package:example/services/singleton_1.dart' as p1;
import 'package:injectable/injectable.dart';

@dev
@injectable
class Helper {
  Helper(p1.Singleton singleton);
}
