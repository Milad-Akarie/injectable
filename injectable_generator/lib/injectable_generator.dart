import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable_annotations.dart';
import 'package:injectable_generator/src/dependency_holder.dart';
import 'package:source_gen/source_gen.dart';

class InjectableGenerator implements GeneratorForAnnotation {
  @override
  TypeChecker get typeChecker => const TypeChecker.fromRuntime(Injectable);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    List<DependencyHolder> depHolders = [];
    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      final dep = await generateForAnnotatedElement(
          annotatedElement.element, annotatedElement.annotation, buildStep);
      if (dep != null) {
        depHolders.add(dep);
      }
    }

    if (depHolders.isNotEmpty) {
      final inputID = buildStep.inputId.changeExtension(".injectable.json");
      buildStep.writeAsString(inputID, json.encode(depHolders));
    }
    return null;
  }

  Future<DependencyHolder> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      return null;
    }

    final ClassElement classElement = element;

    classElement.constructors.forEach((c) {
      typeChecker
          .annotationsOf(c)
          .map((a) => AnnotatedElement(ConstantReader(a), classElement))
          .forEach((a) {
        print(a.annotation.toString());
      });
    });

    return DependencyHolder.fromElement(classElement, annotation);
  }
}
