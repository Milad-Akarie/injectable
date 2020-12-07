import 'package:build_test/build_test.dart';
import 'package:injectable_generator_micropackages/micro_packages/injectable_micro_packages_module_scout.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

main() {
  group('InjectableMicroPackagesModuleScout', () {
    test('should generate json file for class with @MicroPackage()', () async {
      var builder = LibraryBuilder(InjectableMicroPackagesModuleScout(),
          //removes the comments saying it's a generated file
          formatOutput: (generated) =>
              generated.replaceAll(RegExp(r'//.*|\s'), ''),
          generatedExtension: '.json');
      await testBuilder(
        builder,
        {
          'injectable|lib/injectable_micropackages.dart': _annotations,
          'injectable|lib/src/injectable_annotations.dart': _annotationsBase,
          'injectable_generator|lib/example_module.dart': _inputDartFile,
        },
        outputs: {
          'injectable_generator|lib/example_module.json': _expectedOutput
        },
        rootPackage: 'injectable_generator',
      );
    });
  });
}

const _annotations = r'''
export 'src/injectable_annotations.dart';
''';
const _annotationsBase = r'''
class MicroPackage {
  /// The micropackage module/feature name.
  final String moduleName;
  const MicroPackage(this.moduleName);
}
''';
const String _inputDartFile = r'''
    import 'package:injectable/injectable_micropackages.dart';
    @MicroPackage("exampleModule")
    class ExampleModule{
      static void registerModuleDependencies(){}
    }
    ''';
final _expectedOutput =
    r'''{"moduleFileLocation":"package:injectable_generator_micropackages/example_module.dart","moduleName":"exampleModule","moduleClassName":"ExampleModule","methodName":"registerModuleDependencies"}''';
