// general utils
import 'package:analyzer/dart/element/element.dart';

String getImport(Element element) {
  //return early if element has no source

  if (element.source == null) {
    return null;
  }
  // we don't need to import core dart types
  // or core flutter types
  if (!element.source.isInSystemLibrary) {
    final path = element.source.uri.toString();
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

void throwBoxed(String message) {
  final pre = 'Injectable Generator ';
  throw ("\n${pre.padRight(71, '-')}\n$message\n${''.padRight(72, '-')} \n");
}

void throwBoxedIf(bool condition, String message) {
  if (condition) {
    throwBoxed(message);
  }
}

void printBoxed(String message) {
  final pre = 'Injectable Generator ';
  print("${pre.padRight(71, '-')}\n\n$message\n${''.padRight(72, '-')} \n");
}
