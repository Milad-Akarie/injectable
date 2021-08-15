import 'package:example/injector/injector.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

void main() async {
  await configInjector(getIt, env: platformMobile.name);
  print(getIt<ServiceA>(param1: (int input) => input + 1).dependency?.call(1));
}
