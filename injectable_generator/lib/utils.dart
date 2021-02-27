// general utils
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

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

void throwError(String message, {Element? element}) {
  throw InvalidGenerationSourceError(
    message,
    element: element,
  );
}

void throwIf(bool condition, String message, {Element? element}) {
  if (condition) {
    throw InvalidGenerationSourceError(
      message,
      element: element,
    );
  }
}

void printBoxed(String message,
    {String header = '--------------------------'}) {
  final pre = header;
  print("$pre\n$message\n${''.padRight(72, '-')} \n");
}

extension IterableExtenstion<E> on Iterable<E> {
  E? firstOrNull(bool test(E element)) {
    for (var e in this) {
      if (test(e)) {
        return e;
      }
    }
    return null;
  }
}
