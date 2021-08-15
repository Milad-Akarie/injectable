import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:source_gen/source_gen.dart';

import '../utils.dart';

class InjectableConfigGenerator extends GeneratorForAnnotation<InjectableInit> {
  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final generateForDir = annotation
        .read('generateForDir')
        .listValue
        .map((e) => e.toStringValue());

    final usesNullSafety = annotation.read('usesNullSafety').boolValue;

    var targetFile = element.source?.uri;
    var preferRelativeImports =
        annotation.read("preferRelativeImports").boolValue;

    final dirPattern = generateForDir.length > 1
        ? '{${generateForDir.join(',')}}'
        : '${generateForDir.first}';
    final injectableConfigFiles = Glob("$dirPattern/**.injectable.json");

    final jsonData = <Map>[];
    await for (final id in buildStep.findAssets(injectableConfigFiles)) {
      final json = jsonDecode(await buildStep.readAsString(id));
      jsonData.addAll([...json]);
    }

    final deps = <DependencyConfig>[];
    jsonData.forEach((json) => deps.add(DependencyConfig.fromJson(json)));

    final initializerName = annotation.read('initializerName').stringValue;
    final asExtension = annotation.read('asExtension').boolValue;

    final typeResolver =
        ImportableTypeResolverImpl(await buildStep.resolver.libraries.toList());
    final ignoredTypes =
        annotation.read('ignoreUnregisteredTypes').listValue.map(
              (e) => typeResolver.resolveType(e.toTypeValue()!),
            );
    final ignoreTypesInPackages = annotation
        .read('ignoreUnregisteredTypesInPackages')
        .listValue
        .map((e) => e.toStringValue())
        .where((e) => e != null)
        .cast<String>();

    _reportMissingDependencies(
        deps, ignoredTypes, ignoreTypesInPackages, targetFile);
    _validateDuplicateDependencies(deps);
    final generator = LibraryGenerator(
      dependencies: deps,
      targetFile: preferRelativeImports ? targetFile : null,
      initializerName: initializerName,
      asExtension: asExtension,
    );
    final generatedLib = generator.generate();
    final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(),
      orderDirectives: true,
      useNullSafetySyntax: usesNullSafety,
    );
    return DartFormatter().format(generatedLib.accept(emitter).toString());
  }

  void _reportMissingDependencies(
      List<DependencyConfig> deps,
      Iterable<ImportableType> ignoredTypes,
      Iterable<String> ignoredTypesInPackages,
      Uri? targetFile) {
    final messages = [];
    final registeredDeps = deps.map((dep) => dep.type).toSet();
    deps.forEach((dep) {
      dep.dependencies
          .where(
              (d) => !d.isFactoryParam && d.instanceName != kEnvironmentsName)
          .forEach((iDep) {
        if (!registeredDeps.contains(iDep.type) &&
            (!ignoredTypes.contains(iDep.type) &&
                (iDep.type.import == null ||
                    !ignoredTypesInPackages.any((type) =>
                        iDep.type.import!.startsWith('package:$type'))))) {
          messages.add(
              "[${dep.typeImpl}] depends on unregistered type [${iDep.type}] ${iDep.type.import == null ? '' : 'from ${iDep.type.import}'}");
        }
      });
    });

    if (messages.isNotEmpty) {
      messages.add(
          '\nDid you forget to annotate the above class(s) or their implementation with @injectable?');
      printBoxed(messages.join('\n'),
          header: "Missing dependencies in ${targetFile?.path}\n");
    }
  }

  void _validateDuplicateDependencies(List<DependencyConfig> deps) {
    final validatedDeps = <DependencyConfig>[];
    for (var dep in deps) {
      var registered = validatedDeps.where((elm) =>
          elm.type == dep.type && elm.instanceName == dep.instanceName);
      if (registered.isEmpty) {
        validatedDeps.add(dep);
      } else {
        Set<String> registeredEnvironments = registered
            .fold(<String>{}, (prev, elm) => prev..addAll(elm.environments));

        if (registeredEnvironments.isEmpty ||
            dep.environments
                .any((env) => registeredEnvironments.contains(env))) {
          throwBoxed(
              '${dep.typeImpl} [${dep.type}] env: ${dep.environments} \nis registered more than once under the same environment');
        }
      }
    }
  }
}
