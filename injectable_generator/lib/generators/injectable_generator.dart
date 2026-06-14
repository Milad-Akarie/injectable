import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/resolvers/dependency_resolver.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:source_gen/source_gen.dart';

import '../resolvers/utils.dart';

const _typeChecker = TypeChecker.typeNamed(Injectable, inPackage: 'injectable');
const _moduleChecker = TypeChecker.typeNamed(Module, inPackage: 'injectable');

/// Generates intermediate `.injectable.json` files containing serialized dependency configurations.
class InjectableGenerator implements Generator {
  /// Pattern matcher for class names when auto-register is enabled.
  RegExp? _classNameMatcher, _fileNameMatcher;

  /// Whether auto-registration is enabled.
  late bool _autoRegister;

  /// Creates an [InjectableGenerator] with the given [options].
  InjectableGenerator(Map options) {
    _autoRegister = options['auto_register'] ?? false;
    if (_autoRegister) {
      if (options['class_name_pattern'] != null) {
        _classNameMatcher = RegExp(options['class_name_pattern']);
      }
      if (options['file_name_pattern'] != null) {
        _fileNameMatcher = RegExp(options['file_name_pattern']);
      }
    }
  }

  /// Generates JSON configuration for all injectable classes in [library].
  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final allDepsInStep = <DependencyConfig>[];
    final libs = await buildStep.resolver.libraries.toList();
    final resolver = getResolver(libs);
    for (var clazz in library.classes) {
      if (_moduleChecker.hasAnnotationOfExact(clazz)) {
        throwIf(
          !clazz.isAbstract,
          '[${clazz.displayName}] must be an abstract class!',
          element: clazz,
        );
        final executables = <ExecutableElement>[
          ...clazz.getters,
          ...clazz.methods,
        ];
        for (var element in executables) {
          if (element.isPrivate) continue;
          allDepsInStep.add(
            DependencyResolver(resolver).resolveModuleMember(clazz, element),
          );
        }
      } else if (_hasInjectable(clazz) ||
          (_autoRegister && _hasConventionalMatch(clazz))) {
        allDepsInStep.add(
          DependencyResolver(resolver).resolve(clazz),
        );
      }
    }
    return allDepsInStep.isNotEmpty ? jsonEncode(allDepsInStep) : null;
  }

  /// Returns an [ImportableTypeResolverImpl] for the given libraries.
  ImportableTypeResolver getResolver(List<LibraryElement> libs) {
    return ImportableTypeResolverImpl(libs);
  }

  /// Checks if the given [element] has the @injectable annotation.
  bool _hasInjectable(ClassElement element) {
    return _typeChecker.hasAnnotationOf(element);
  }

  /// Checks if the given [clazz] matches the conventional naming pattern.
  bool _hasConventionalMatch(ClassElement clazz) {
    if (clazz.isAbstract) {
      return false;
    }
    final fileName = clazz.firstFragment.libraryFragment.source.shortName
        .replaceFirst('.dart', '');
    return (_classNameMatcher != null &&
            _classNameMatcher!.hasMatch(clazz.displayName)) ||
        (_fileNameMatcher != null && _fileNameMatcher!.hasMatch(fileName));
  }
}
