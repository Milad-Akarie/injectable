import 'package:example/injector/Service.dart';
import 'package:example/injector/injector.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';

void main(List<String> arguments) {
  configInjector(environmentFilter: NoEnvOrContainsAny({prod.name, platformMobile.name}));
  print(getIt<Service>().environments);
}
