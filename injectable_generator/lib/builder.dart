// coverage:ignore-file
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/injectable_config_generator.dart';
import 'generators/injectable_generator.dart';

Builder injectableBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableGenerator(options.config),
    formatOutput: (generated, _) => generated.replaceAll(RegExp(r'//.*|\s'), ''),
    generatedExtension: '.injectable.json',
  );
}

Builder injectableConfigBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableConfigGenerator(),
    generatedExtension: '.config.dart',
    additionalOutputExtensions: ['.module.dart'],
  );
}
