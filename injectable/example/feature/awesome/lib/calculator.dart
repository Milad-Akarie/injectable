
import 'package:injectable/injectable.dart';

@injectable
class Calculator {

  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;

  Calculator(Dep dep);
}


@Injectable()
class Dep{}