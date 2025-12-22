import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:injectable_generator/lean_builder/resolvers/lean_dependency_resolver.dart';
import 'package:injectable_generator/lean_builder/resolvers/lean_importable_type_resolver.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';
import 'package:lean_builder/type.dart';

import 'build_utils.dart';

const _typeChecker = TypeChecker.typeNamed(Injectable, inPackage: 'injectable');
const _moduleChecker = TypeChecker.typeNamed(Module, inPackage: 'injectable');

@LeanBuilder(generateToCache: true, applies: {'InjectableConfigGenerator'})
class LeanInjectableBuilder extends Builder {
  RegExp? _classNameMatcher, _fileNameMatcher;
  late bool _autoRegister;
  bool get autoRegister => _autoRegister;
  RegExp? get classNameMatcher => _classNameMatcher;
  RegExp? get fileNameMatcher => _fileNameMatcher;

  LeanInjectableBuilder(BuilderOptions options) {
    final config = options.config;
    _autoRegister = config['auto_register'] ?? false;
    if (_autoRegister) {
      if (config['class_name_pattern'] != null) {
        _classNameMatcher = RegExp(config['class_name_pattern']);
      }
      if (config['file_name_pattern'] != null) {
        _fileNameMatcher = RegExp(config['file_name_pattern']);
      }
    }
  }

  @override
  Set<String> get outputExtensions => {'.injectable.ln.json'};

  @override
  bool shouldBuildFor(BuildCandidate candidate) {
    return candidate.isDartSource && candidate.hasClasses;
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final library = buildStep.resolver.resolveLibrary(buildStep.asset);
    final allDepsInStep = <DependencyConfig>[];
    final resolver = getTypeResolver(buildStep.resolver);
    for (var clazz in library.classes) {
      if (_moduleChecker.hasAnnotationOfExact(clazz)) {
        throwIf(
          !clazz.hasAbstract,
          '[${clazz.name}] must be an abstract class!',
          element: clazz,
        );
        final executables = <ExecutableElement>[
          ...clazz.accessors.where((e) => e.isGetter),
          ...clazz.methods,
        ];
        for (var element in executables) {
          if (element.isPrivate) continue;
          allDepsInStep.add(
            LeanDependencyResolver(
              resolver,
            ).resolveModuleMember(clazz, element),
          );
        }
      } else if (_hasInjectable(clazz) ||
          (_autoRegister && _hasConventionalMatch(clazz))) {
        allDepsInStep.add(
          LeanDependencyResolver(resolver).resolve(clazz),
        );
      }
    }
    if (allDepsInStep.isNotEmpty) {
      await buildStep.writeAsString(
        jsonEncode(allDepsInStep),
        extension: '.injectable.ln.json',
      );
    }
  }

  LeanTypeResolver getTypeResolver(Resolver resolver) {
    return LeanTypeResolverImpl(resolver);
  }

  bool _hasInjectable(ClassElement element) {
    return _typeChecker.hasAnnotationOf(element);
  }

  bool _hasConventionalMatch(ClassElement clazz) {
    if (clazz.hasAbstract) {
      return false;
    }
    final fileName = clazz.thisType.declarationRef.srcUri.path.replaceFirst(
      '.dart',
      '',
    );
    return (_classNameMatcher != null &&
            _classNameMatcher!.hasMatch(clazz.name)) ||
        (_fileNameMatcher != null && _fileNameMatcher!.hasMatch(fileName));
  }
}
