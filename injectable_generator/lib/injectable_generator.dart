import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable_annotations.dart';
import 'package:injectable_generator/src/dependency_config.dart';
import 'package:injectable_generator/src/dependency_resolver.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

class InjectableGenerator implements GeneratorForAnnotation {
  @override
  TypeChecker get typeChecker => const TypeChecker.fromRuntime(Injectable);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    List<DependencyConfig> depConfigs = [];
    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      final dep = await generateForAnnotatedElement(
          annotatedElement.element, annotatedElement.annotation, buildStep);
      if (dep != null) {
        depConfigs.add(dep);
      }
    }

    if (depConfigs.isNotEmpty) {
      final inputID = buildStep.inputId.changeExtension(".injectable.json");
      buildStep.writeAsString(inputID, json.encode(depConfigs));
    }
    return null;
  }

  Future<DependencyConfig> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      return null;
    } else if ((element as ClassElement).isAbstract) {
      throwBoxed('[${element.name}] is abstract and can not be registered!'
          '\nAnnotate your implmentation and bind it'
          ' @Injectable(bindto: ${element.name})');
    }

    return DependencyResolver(element as ClassElement, annotation).resolve();
  }
}
