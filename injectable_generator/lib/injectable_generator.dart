import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'dependency_resolver.dart';

const TypeChecker bindChecker = const TypeChecker.fromRuntime(Bind);
const TypeChecker typeChecker = const TypeChecker.fromRuntime(Injectable);

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
      if ((autoRegister && _hasConventionalMatch(clazz)) ||
          _hasInjectable(clazz)) {
        final deps = await generateForElement(clazz, buildStep);
        if (deps.isNotEmpty) {
          allDepsInStep.addAll(deps);
        }
      }
    }

    if (allDepsInStep.isNotEmpty) {
      final inputID = buildStep.inputId.changeExtension(".injectable.json");
      buildStep.writeAsString(inputID, json.encode(allDepsInStep));
    }
    return null;
  }

  Future<List<DependencyConfig>> generateForElement(
      ClassElement clazz, BuildStep buildStep) async {
    final deps = <DependencyConfig>[];

    if (bindChecker.hasAnnotationOfExact(clazz, throwOnUnresolved: false)) {
      bindChecker
          .annotationsOfExact(clazz)
          .map((a) => ConstantReader(a))
          .forEach((bindConst) {
        _validTypeBind(clazz, bindConst);
        deps.add(DependencyResolver(clazz, bindConst).resolve());
      });
      return deps;
    } else {
      throwBoxedIf(
          clazz.isAbstract,
          '[${clazz.name}] is abstract and can not be registered directly!'
          '\nTry binding it to an Implementation using @Bind.toType() or @Bind.toNamedType()');
      return deps..add(DependencyResolver(clazz).resolve());
    }
  }

  bool _hasInjectable(ClassElement element) {
    return typeChecker.firstAnnotationOfExact(element,
            throwOnUnresolved: false) !=
        null;
  }

  _validTypeBind(ClassElement clazz, ConstantReader bindConst) {
    final bindType = bindConst.peek('type')?.typeValue;
    if (clazz.isAbstract) {
      throwBoxedIf(
          bindType == null,
          '[${clazz.name}] is abstract and can not be registered directly!'
          '\nTry binding it to an Implementation using @Bind.toType() or @Bind.toNamedType()');

      throwBoxedIf((bindType.element is! ClassElement),
          '[${bindType.name}] is not a class element!');

      throwBoxedIf(
          !(bindType.element as ClassElement)
              .allSupertypes
              .contains(clazz.thisType),
          '[${clazz.name}] can not be binded to [${bindType.name}]! \nbecause it does not implement or extend it');
    }
  }

  bool _hasConventionalMatch(ClassElement clazz) {
    final fileName = clazz.source.shortName.replaceFirst('.dart', '');
    return (_classNameMatcher != null &&
            _classNameMatcher.hasMatch(clazz.name)) ||
        (_fileNameMatcher != null && _fileNameMatcher.hasMatch(fileName));
  }
}
