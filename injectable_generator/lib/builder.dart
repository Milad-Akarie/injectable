import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/injectable_config_generator.dart';
import 'generators/injectable_generator.dart';

Builder injectableBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableGenerator(options.config),
    formatOutput: (generated) => generated.replaceAll(RegExp(r'//.*|\s'), ''),
    generatedExtension: '.injectable.json',
  );
}

Builder injectableConfigBuilder(BuilderOptions options) {
  final generator = InjectableConfigGenerator();
  if (options.config.containsKey("build_extensions")) {
    return LibraryBuilder(generator, options: options);
  } else {
    return LibraryBuilder(generator,
        generatedExtension: '.config.dart',
        additionalOutputExtensions: ['.module.dart']);
  }
}
