import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'injectable_config_generator.dart';
import 'injectable_generator.dart';
import 'injectable_micro_packages_scout.dart';
import 'injetactable_micro_packages_generator.dart';

Builder injectableBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableGenerator(options.config),
    formatOutput: (generated) => generated.replaceAll(RegExp(r'//.*|\s'), ''),
    generatedExtension: '.injectable.json',
  );
}

Builder injectableConfigBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableConfigGenerator(),
    generatedExtension: '.config.dart',
  );
}

/*
Builder microPackagesScout(BuilderOptions options){
  return LibraryBuilder(
      InjectableMicroPackagesScout(),
      formatOutput: (generated) => generated.replaceAll(RegExp(r'//.*|\s'), ''),
      generatedExtension: '.micro.json'
  );
}
*/

Builder microPackagesBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableMicroPackagesGenerator(),
    generatedExtension: '.micropackage.config.part',
  );
}