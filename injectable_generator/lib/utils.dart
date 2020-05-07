// general utils
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';

// Checks if source is from dart:core library
bool isCoreDartType(Source source) {
  return source.isInSystemLibrary && source.uri.path.startsWith('core/');
}

String getImport(Element element) {
  // prefer library source, because otherwise "part of"-files will lead to
  // compile errors due to bad imports in the generated code
  final source = element.librarySource ?? element.source;

  //return early if element has no source
  if (source == null) {
    return null;
  }

  // we don't need to import core dart types
  if (!isCoreDartType(source)) {
    final path = source.uri.toString();
    return path;
  }
  return null;
}

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

void throwBoxedIf(bool condition, String message) {
  if (condition) {
    throwBoxed(message);
  }
}

void printBoxed(String message) {
  final pre = 'Injectable Generator ';
  print("${pre.padRight(72, '-')}\n\n$message\n${''.padRight(72, '-')} \n");
}

String stripGenericTypes(String type) => RegExp('^([^<]*)').stringMatch(type);
