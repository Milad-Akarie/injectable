import 'package:example_micro_package/injection.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';

@MicroPackage("exampleModule")
class ExampleModule{
  static void registerModuleDependencies(GetIt get){
    configureInjection();
  }

}