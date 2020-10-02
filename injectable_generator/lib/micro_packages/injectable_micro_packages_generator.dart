import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable_generator/model/micro_package_model.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;


/// Aggregate builder
class InjectableMicroPackagesGenerator
    extends GeneratorForAnnotation<MicroPackageRootInit> {

  /// This method is called for each
  /// source that has @microPackage annotation.
  /// The goal is to add a part file to the root injection.config.dart file
  /// This part file will call the registration of micro module dependencies.
  /// It searches for micro.json files, which are the work of InjectableMicroPackagesScout
  /// This generator will fail if a micro_packages.json file is not found in the lib/ folder
  /// TODO: this script only works if injection.dart has the imports for the modules... this doesn't make much sense.
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    log.fine("generateForAnnotatedElement");

    var microPackageNames = await _getMicroPackageConfig(path.join("lib","micro_packages.json"), buildStep);
    var generatedCode = '';

    for (var package in microPackageNames) {
      log.fine('generating for package $package');
      generatedCode += " ${package.moduleClassName}.${package.methodName}(getIt); \n";
    }

    var microPackagesImportDirectives = microPackageNames
        .map((microPackageNames) =>
            Directive.import(microPackageNames.moduleFileLocation))
        .toSet();

    final clazz = Library(
      (lib) => lib
        ..directives.addAll(microPackagesImportDirectives)
        ..body.add(
          Class((clazz) => clazz
            ..name = 'MicroPackagesConfig'
            ..methods.addAll([
              Method((m) => m
                ..name = 'registerMicroModules'
                ..static = true
                //..docs.add("This method calls registerModuleDependencies in known micro packages")
                ..requiredParameters.addAll([
                  Parameter((p) => p
                    ..type = refer('GetIt', 'package:get_it/get_it.dart')
                    ..name = 'getIt')
                ])
                ..body = Code(generatedCode))
            ])),
        ),
    );

    final emitter = DartEmitter(Allocator.simplePrefixing());
    return DartFormatter().format('${clazz.accept(emitter)}');
  }

  /// Finds generated json file, containing all the microPackageModule declarations
  Future<Set<MicroPackageModuleModel>> _getMicroPackageConfig (
      String filePath,
      BuildStep buildStep) async {
    var microPackagesJson = await buildStep.readAsString(
        AssetId(buildStep.inputId.package, filePath));
    return (jsonDecode(microPackagesJson) as Iterable)
    .map((next) => MicroPackageModuleModel.fromJson(next)).toSet();


  }

  /// @deprecated
  /// This method uses resolver to fetch the libraries that contain
  /// the annotation @microPackage
  /// Although it's a clean way of doing so, it only works
  /// it the input file ( the one that has the annotation @MicroPackageRootInit
  /// has imports for the micro package libraries...
  /// Therefore is useless!
  Future<Set<MicroPackageModuleModel>> _getMicroPackageLibraries(
      Resolver resolver) async {
    return resolver.libraries
        .where((library) {
          return !library.isInSdk &&
              !library.isDartCore &&
              library.nameLength > 0;
        })
        .map((lib) => LibraryReader(lib))
        .where((libReader) =>
            libReader.classes.length > 0 &&
            libReader.classes.first.metadata.length > 0)
        .where((libReader) => libReader.classes.first.metadata.first.element
            .toString()
            .contains("microPackage"))
        .map((microPackageLib) {
          return MicroPackageModuleModel(
              microPackageLib.element.location.toString(),
              microPackageLib.element.name,
              microPackageLib.classes.first.name);
        })
        .toSet();
  }
}
