import 'package:build_test/build_test.dart';
import 'package:injectable_generator/micro_packages/injectable_micro_packages_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

///test for micro_packages/injectable_micro_packages_generator
main() {
  group('testing micro_packages/injectable_micro_packages_generator', () {
    test('should generate valid injector.config.micropackage.dart', () async {
      await testBuilder(
        builder,
        {
          'injectable_generator|lib/injector.dart': _inputDartFile,
          'injectable_generator|lib/micro_packages.json': _microPackageDefinition1,
        },
        outputs: {
          'injectable_generator|lib/injector.config.micropackage.dart': _expectedOutput1,
        },
        reader: await PackageAssetReader.currentIsolate(),
        rootPackage: 'injectable_generator',
      );
    });

    test('should generate valid injector.config.micropackage.dart with multiple modules', () async {
      await testBuilder(
        builder,
        {
          'injectable_generator|lib/injector.dart': _inputDartFile,
          'injectable_generator|lib/micro_packages.json': _microPackageDefinition2,
        },
        outputs: {
          'injectable_generator|lib/injector.config.micropackage.dart': _expectedOutput2,
        },
        reader: await PackageAssetReader.currentIsolate(),
        rootPackage: 'injectable_generator',
      );
    });

  });
}

var builder = LibraryBuilder(
  InjectableMicroPackagesGenerator(),
  generatedExtension: '.config.micropackage.dart',
);
const _microPackageDefinition1 = r'''
[
  {
    "moduleFileLocation": "package:example_micro_package/example_module.dart",
    "moduleName": "exampleModule",
    "moduleClassName": "ExampleModule",
    "methodName": "registerModuleDependencies"
  }
]
''';

const _microPackageDefinition2 = r'''
[
  {
    "moduleFileLocation": "package:example_micro_package/example_module.dart",
    "moduleName": "exampleModule",
    "moduleClassName": "ExampleModule",
    "methodName": "registerModuleDependencies"
  },
  {
    "moduleFileLocation": "package:other_module/other_module.dart",
    "moduleName": "otherModule",
    "moduleClassName": "OtherModule",
    "methodName": "thisIsTheNameIWant"
  }
]
''';
const _inputDartFile = r'''
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injector.config.dart';
const platformMobile = Environment("platformMobile");
const platformWeb = Environment("platformWeb");
GetIt getIt = GetIt.instance;
/// Micropackages root init should be used when the project uses
/// a micro package folder structure
/// If this is not the case, then fallback to InjectableInit annotation.
/// MicroPackageRootInit assumes that a folder named features exist and that is
/// the place where you place your micro packages projects
@MicroPackageRootInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: true,
)
void configInjector({String env, EnvironmentFilter environmentFilter}) {
  getIt.$initGetIt(environmentFilter: environmentFilter);
}
''';

const _expectedOutput1 = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableMicroPackagesGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:example_micro_package/example_module.dart';

class MicroPackagesConfig {
  static registerMicroModules(_i1.GetIt getIt) {
    ExampleModule.registerModuleDependencies(getIt);
  }
}
''';

const _expectedOutput2 = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableMicroPackagesGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:example_micro_package/example_module.dart';
import 'package:other_module/other_module.dart';

class MicroPackagesConfig {
  static registerMicroModules(_i1.GetIt getIt) {
    ExampleModule.registerModuleDependencies(getIt);
    OtherModule.thisIsTheNameIWant(getIt);
  }
}
''';
