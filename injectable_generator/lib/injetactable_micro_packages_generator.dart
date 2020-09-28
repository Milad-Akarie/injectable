import 'package:injectable/injectable.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable_generator/injectable_micro_packages_scout.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

/// Aggregate builder
class InjectableMicroPackagesGenerator
    extends GeneratorForAnnotation<MicroPackageRootInit> {
  /// This method is called for each
  /// source that has @microPackage annotation.
  /// The goal is to add a part file to the root injection.config.dart file
  /// This part file will call the registration of micro module dependencies.
  /// It searches for micro.json files, which are the work of InjectableMicroPackagesScout
  /// TODO: this script only works if injection.dart has the imports for the modules... this doesn't make much sense.
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    var microPackageNames = await buildStep.resolver.libraries
        .where((library) {
          return !library.isInSdk &&
              !library.isDartCore &&
              library.nameLength > 0;
        })
        .map((lib) => LibraryReader(lib))
        /*.map((libReader) {
          log.warning(
              "before classes filter libReader ${libReader.element.identifier}");
          return libReader;
        })*/
        .where((libReader) =>
            libReader.classes.length > 0 &&
            libReader.classes.first.metadata.length > 0)
        /* .map((libReader) {
          log.warning("after classes filter libReader ${libReader.toString()}");
          return libReader;
        })*/
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

    var generatedCode = '';

    for (var package in microPackageNames) {
      var name = package.moduleClassName;
      generatedCode += package.moduleClassName +
          '.registerModuleDependencies(getIt);' +
          "\n";
    }

    final library = Library((lib) => lib
      ..directives.add(Directive.part("injection.config.dart"))
      ..body.add(Method((m) => m
        ..name = 'registerMicroModules'
        ..requiredParameters.addAll([
          Parameter((p) => p
            ..type = refer('GetIt','package:get_it/get_it.dart')
            ..name = 'getIt')
        ])
        ..body = Code(generatedCode))));

    final emitter = DartEmitter(Allocator.simplePrefixing());
    return DartFormatter().format('${library.accept(emitter)}');
  }
}

/// Represents a micro package
class MicroPackageModuleModel {
  /// the moduleFileLocation, like package:<name>/<name>.dart
  final String moduleFileLocation;

  /// the module or package name
  final String moduleName;

  /// Name of the class that has
  /// registerModuleDependencies method and @microPackage annotation
  final String moduleClassName;

  MicroPackageModuleModel(
      this.moduleFileLocation, this.moduleName, this.moduleClassName);
}
