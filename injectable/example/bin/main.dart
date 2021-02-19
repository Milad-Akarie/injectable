import 'package:example/injector/Service.dart';
import 'package:example/injector/injector.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

GetIt getIt = GetIt.instance;

void main() async {
  await configInjector(getIt, env: platformWeb.name);
  print("working");
  print(getIt<Set<String>>(instanceName: kEnvironmentsName));
  print(getIt<AbstractService>());
}
