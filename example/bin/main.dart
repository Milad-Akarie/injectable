import 'package:example/injector/injector.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable_generator/dependency_config.dart';

final GetIt getIt = GetIt.instance;

void main(List<String> arguments) {
//  $initGetIt(getIt, environment: 'environment');
  var imports = [ImportableType(name: "one"), ImportableType(name: "Two")];
  imports.forEach((element) => print("${element.name} ${element.prefix}"));

  var mapped = imports.map((e) => e.name == "one" ? e.copyWith(prefix: 'prefix') : e);

  mapped.forEach((element) => print("${element.name} ${element.prefix}"));
}
