import 'injector.dart';
import 'services/register_module.dart';

void main(List<String> arguments) {
  configureDependencies();
  print(getIt<Client>().url);
}
