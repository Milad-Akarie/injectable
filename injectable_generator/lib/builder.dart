// coverage:ignore-file
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/injectable_config_generator.dart';
import 'generators/injectable_generator.dart';

/// Creates a builder that generates intermediate `.injectable.json` files
/// containing serialized dependency configurations.
Builder injectableBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableGenerator(options.config),
    formatOutput: (generated, _) =>
        generated.replaceAll(RegExp(r'//.*|\s'), ''),
    generatedExtension: '.injectable.json',
  );
}

/// Creates a builder that generates the final `.config.dart` file
/// with dependency registration code.
Builder injectableConfigBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableConfigGenerator(),
    generatedExtension: '.config.dart',
    additionalOutputExtensions: ['.module.dart'],
  );
}
