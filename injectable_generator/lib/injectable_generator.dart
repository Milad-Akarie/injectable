import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'dependency_resolver.dart';

const TypeChecker typeChecker = TypeChecker.fromRuntime(Injectable);
const TypeChecker moduleChecker = TypeChecker.fromRuntime(RegisterModule);

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
        throwIf(
          !clazz.isAbstract,
          '[${clazz.name}] must be an abstract class!',
          element: clazz,
        );
        final executables = <ExecutableElement>[
          ...clazz.accessors,
          ...clazz.methods,
        ];
        for (var annotatedElement in executables) {
          if (annotatedElement.isPrivate) continue;
          allDepsInStep.add(await DependencyResolver(getResolver(buildStep))
              .resolveModuleMember(clazz, annotatedElement));
        }
      } else if (_hasInjectable(clazz) ||
          (autoRegister && _hasConventionalMatch(clazz))) {
        allDepsInStep.add(
            await DependencyResolver(getResolver(buildStep)).resolve(clazz));
      }
    }

    return allDepsInStep.isNotEmpty ? json.encode(allDepsInStep) : null;
  }

  Resolver getResolver(BuildStep buildStep) {
    return buildStep.resolver;
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
