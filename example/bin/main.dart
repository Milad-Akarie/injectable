import 'package:example/injector/injector.dart';
import 'package:example/services/register_module.dart';
import 'package:injectable/injectable.dart';

void main(List<String> arguments) {
  configureDependencies(Environment.dev);
  print(getIt<Client>().url);
}

