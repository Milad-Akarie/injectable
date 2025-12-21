// general utils
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

void throwError(String message, {Element? element}) {
  throw InvalidGenerationSourceError(message, element: element);
}

void throwIf(bool condition, String message, {Element? element}) {
  if (condition) {
    throw InvalidGenerationSourceError(message, element: element);
  }
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
