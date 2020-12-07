import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'injectable_micro_packages_config_aggregator.dart';
import 'injectable_micro_packages_generator.dart';
import 'injectable_micro_packages_module_scout.dart';

/// see [InjectableMicroPackagesModuleScout]
/// This builder runs on micropackages
Builder microPackagesModuleScout(BuilderOptions options) {
  return LibraryBuilder(
    InjectableMicroPackagesModuleScout(),
    formatOutput: (generated) => generated.replaceAll(RegExp(r'//.*|\s'), ''),
    generatedExtension: '.micropackage.json',
  );
}

/// see [InjectableMicroPackagesConfigAggregator] documentation
/// This builder runs on RootMicroPackage
Builder microPackagesConfigAggregator(BuilderOptions options) {
    return InjectableMicroPackagesConfigAggregator();
}

/// see [InjectableMicroPackagesGenerator] documentation
/// This builder runs on RootMicroPackage
Builder microPackagesBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableMicroPackagesGenerator(),
    generatedExtension: '.config.micropackage.dart',
  );
}
