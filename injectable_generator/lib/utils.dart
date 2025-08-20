// general utils
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/resolvers/dependency_resolver.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:source_gen/source_gen.dart';

import 'models/dependency_config.dart';

String capitalize(String s) {
  if (s.length < 2) {
    return s.toUpperCase();
  }
  return s[0].toUpperCase() + s.substring(1);
}

String toCamelCase(String s) {
  if (s.length < 2) {
    return s.toLowerCase();
  }
  return s[0].toLowerCase() + s.substring(1);
}

void throwBoxed(String message) {
  final pre = 'Injectable Generator ';
  throw ("\n${pre.padRight(72, '-')}\n$message\n${''.padRight(72, '-')} \n");
}

void throwSourceError(String message) {
  final pre = 'Injectable Generator ';
  throw ("\n${pre.padRight(72, '-')}\n$message\n${''.padRight(72, '-')} \n");
}

void throwError(String message, {Element2? element}) {
  throw InvalidGenerationSourceError(
    message,
    element: element,
  );
}

void throwIf(bool condition, String message, {Element2? element}) {
  if (condition) {
    throw InvalidGenerationSourceError(
      message,
      element: element,
    );
  }
}

void printBoxed(String message, {String header = '--------------------------'}) {
  final pre = header;
  print("$pre\n$message\n${''.padRight(72, '-')} \n");
}

extension IterableExtenstion<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var e in this) {
      if (test(e)) {
        return e;
      }
    }
    return null;
  }
}

Future<Iterable<DependencyConfig>> generateDependenciesJson({
  required LibraryReader library,
  required List<LibraryElement2> libs,
  required bool autoRegister,
  required RegExp? classNameMatcher,
  required RegExp? fileNameMatcher,
}) async {
  final deps = <DependencyConfig>[];

  for (var clazz in library.classes) {
    if (hasModuleAnnotation(clazz)) {
      throwIf(
        !clazz.isAbstract,
        '[${clazz.displayName}] must be an abstract class!',
        element: clazz,
      );
      final executables = <ExecutableElement2>[
        ...clazz.getters2,
        ...clazz.methods2,
      ];
      for (var element in executables) {
        if (element.isPrivate) continue;
        deps.add(
          DependencyResolver(
            getResolver(libs),
          ).resolveModuleMember(clazz, element),
        );
      }
    } else if (hasInjectable(clazz) ||
        (autoRegister && hasConventionalMatch(clazz, classNameMatcher, fileNameMatcher))) {
      deps.add(DependencyResolver(
        getResolver(libs),
      ).resolve(clazz));
    }
  }

  return deps;
}

const TypeChecker _typeChecker = TypeChecker.fromRuntime(Injectable);
const TypeChecker _moduleChecker = TypeChecker.fromRuntime(Module);

bool hasModuleAnnotation(ClassElement2 clazz) {
  return _moduleChecker.hasAnnotationOfExact(clazz);
}

bool hasInjectable(ClassElement2 element) {
  return _typeChecker.hasAnnotationOf(element);
}

// checks for matches defined by auto registration options
bool hasConventionalMatch(ClassElement2 clazz, RegExp? classNameMatcher, RegExp? fileNameMatcher) {
  if (clazz.isAbstract) {
    return false;
  }
  final fileName = clazz.firstFragment.libraryFragment.source.shortName.replaceFirst('.dart', '');

  return (classNameMatcher != null && classNameMatcher.hasMatch(clazz.displayName)) ||
      (fileNameMatcher != null && fileNameMatcher.hasMatch(fileName));
}

ImportableTypeResolver getResolver(List<LibraryElement2> libs) {
  return ImportableTypeResolverImpl(libs);
}

/// Extension helpers for [DartType]
extension DartTypeX on DartType {
  /// Returns the display string of this type
  /// without nullability suffix
  String get nameWithoutSuffix {
    final name = getDisplayString();
    return name.endsWith('?') ? name.substring(0, name.length - 1) : name;
  }
}
