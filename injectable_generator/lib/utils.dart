// general utils

/// Capitalizes the first character of a string.
String capitalize(String s) {
  if (s.length < 2) {
    return s.toUpperCase();
  }
  return s[0].toUpperCase() + s.substring(1);
}

/// Converts a string to camelCase format.
String toCamelCase(String s) {
  if (s.length < 2) {
    return s.toLowerCase();
  }
  return s[0].toLowerCase() + s.substring(1);
}

/// Throws a formatted error message with box styling.
void throwBoxed(String message) {
  final pre = 'Injectable Generator ';
  throw ("\n${pre.padRight(72, '-')}\n$message\n${''.padRight(72, '-')} \n");
}

/// Throws a formatted source error message with box styling.
void throwSourceError(String message) {
  final pre = 'Injectable Generator ';
  throw ("\n${pre.padRight(72, '-')}\n$message\n${''.padRight(72, '-')} \n");
}

/// Prints a formatted message with box styling.
void printBoxed(
  String message, {
  String header = '--------------------------',
}) {
  final pre = header;
  print("$pre\n$message\n${''.padRight(72, '-')} \n");
}

/// Extension on [Iterable] providing a `firstWhereOrNull` method.
extension IterableExtenstion<E> on Iterable<E> {
  /// Returns the first element that satisfies [test], or null if none do.
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var e in this) {
      if (test(e)) {
        return e;
      }
    }
    return null;
  }
}
