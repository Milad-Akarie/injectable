import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'injectable_config_generator.dart';
import 'injectable_generator.dart';

Builder injectableBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableGenerator(options.config),
    generatedExtension: '.injectable.json',
  );
}

Builder injectableConfigBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableConfigGenerator(),
    generatedExtension: '.iconfig.dart',
  );
}
