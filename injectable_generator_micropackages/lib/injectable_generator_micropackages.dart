import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'package:injectable_micropackages/injectable_micropackages.dart';
import 'package:injectable_generator_micropackages/importable_type_resolver.dart';
import 'package:injectable_generator_micropackages/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'dependency_resolver.dart';

const TypeChecker typeChecker = TypeChecker.fromRuntime(Injectable);
const TypeChecker moduleChecker = TypeChecker.fromRuntime(Module);

class InjectableGenerator implements Generator {
  RegExp? _classNameMatcher, _fileNameMatcher;
  late bool autoRegister;

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
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
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
        for (var element in executables) {
          if (element.isPrivate) continue;
          allDepsInStep.add(await DependencyResolver(getResolver(await buildStep.resolver.libraries.toList())).resolveModuleMember(clazz, element));
        }
      } else if (_hasInjectable(clazz) || (autoRegister && _hasConventionalMatch(clazz))) {
        allDepsInStep.add(await DependencyResolver(getResolver(await buildStep.resolver.libraries.toList())).resolve(clazz));
      }
    }

    return allDepsInStep.isNotEmpty ? jsonEncode(allDepsInStep) : null;
  }

  ImportableTypeResolver getResolver(List<LibraryElement> libs) {
    return ImportableTypeResolverImpl(libs);
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
        _classNameMatcher!.hasMatch(clazz.name)) ||
        (_fileNameMatcher != null && _fileNameMatcher!.hasMatch(fileName));
  }
}
