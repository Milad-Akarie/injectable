import 'package:example/injector.dart';
import 'package:example/services/register_module.dart';

void main(List<String> arguments) {
  configureDependencies();
  print(getIt<Client>().url);
}
