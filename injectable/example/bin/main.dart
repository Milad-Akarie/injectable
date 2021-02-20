import 'package:example/injector/injector.dart';
import 'package:example/services/abstract_service.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

void main() async {
  await configInjector(getIt, env: platformWeb.name);
  print(getIt<AbstractService>());
}
