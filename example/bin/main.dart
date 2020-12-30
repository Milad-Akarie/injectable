import 'package:example/injector/Service.dart';
import 'package:example/injector/injector.dart';
import 'package:injectable/injectable.dart';

void main(List<String> arguments) {
  configInjector(environmentFilter: NoEnvOrContains(platformMobile.name));

  print(getIt<Service>().environments);
}
