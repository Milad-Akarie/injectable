import 'package:example/injector/injector.config.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

void main() {
  $initGetIt(getIt);
}
