import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'dependency_resolver.dart';

const TypeChecker typeChecker = const TypeChecker.fromRuntime(Injectable);
const TypeChecker moduleChecker = const TypeChecker.fromRuntime(RegisterModule);

class InjectableGenerator implements Generator {
  RegExp _classNameMatcher, _fileNameMatcher;
  bool autoRegister;
  InjectableGenerator(Map options) {
    autoRegister = options['auto_register'] ?? false;
    if (autoRegister) {
      if (options['class_name_pattern'] != null) {
        _classNameMatcher = RegExp(options['class_name_pattern']);
      }
      if (options['file_name_pattern'] != null) {
        _fileNameMatcher = RegExp(options['file_name_pattern']);
      }
    }
  }

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final allDepsInStep = <DependencyConfig>[];

    for (var clazz in library.classes) {
      if (moduleChecker.hasAnnotationOfExact(clazz)) {
        throwBoxedIf(
            !clazz.isAbstract, '[${clazz.name}] must be an abstract class!');

        for (var annotatedElement in clazz.accessors) {
          allDepsInStep.add(await DependencyResolver(buildStep.resolver)
              .resolveAccessor(clazz, annotatedElement));
        }
      } else if (_hasInjectable(clazz) ||
          (autoRegister && _hasConventionalMatch(clazz))) {
        allDepsInStep
            .add(await DependencyResolver(buildStep.resolver).resolve(clazz));
      }
    }

    if (allDepsInStep.isNotEmpty) {
      final inputID = buildStep.inputId.changeExtension(".injectable.json");
      buildStep.writeAsString(inputID, json.encode(allDepsInStep));
    }
    return null;
  }

  bool _hasInjectable(ClassElement element) {
    return typeChecker.hasAnnotationOf(element);
  }

  bool _hasConventionalMatch(ClassElement clazz) {
    if (clazz.isAbstract) {
      return false;
    }
    final fileName = clazz.source.shortName.replaceFirst('.dart', '');
    return (_classNameMatcher != null &&
            _classNameMatcher.hasMatch(clazz.name)) ||
        (_fileNameMatcher != null && _fileNameMatcher.hasMatch(fileName));
  }
}
