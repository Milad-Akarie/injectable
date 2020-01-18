// general utils

import 'package:analyzer/dart/element/element.dart';

String getImport(Element element) {
  if (!element.source.isInSystemLibrary) {
    final path = element.source.uri.toString();

    return "'$path'";
  } else
    return null;

  // final path = uri.toString();
  // // we don't need to import core dart types
  // // or core flutter types
  // if (!path.startsWith('dart:core/') && !path.startsWith('package:flutter/')) {
  // } else {
  //   return null;
  // }
}

String toLowerCamelCase(String s) {
  return s[0].toLowerCase() + s.substring(1);
}

String capitalize(String s) {
  return s[0].toUpperCase() + s.substring(1);
}
