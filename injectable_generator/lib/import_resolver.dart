import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

abstract class ImportResolver {
  String resolve(Element element);

  Set<String> resolveAll(DartType type);
}

class ImportResolverImpl extends ImportResolver {
  final List<LibraryElement> libs;

  ImportResolverImpl(this.libs);

  String resolve(Element element) {
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element)) {
      return null;
    }

    for (var lib in libs) {
      if (lib.source != null &&
          !_isCoreDartType(lib) &&
          lib.exportNamespace.definedNames.keys.contains(element.name)) {
        return lib.source.uri.toString();
      }
    }
    return null;
  }

  static String relative(String path, Uri to) {
    var fileUri = Uri.parse(path);
    var libName = to.pathSegments.first;
    if ((to.scheme == 'package' &&
            fileUri.scheme == 'package' &&
            fileUri.pathSegments.first == libName) ||
        (to.scheme == 'asset' && fileUri.scheme != 'package')) {
      return p.posix
          .relative(fileUri.path, from: to.path)
          .replaceFirst('../', '');
    } else {
      return path;
    }
  }

  bool _isCoreDartType(Element element) {
    return element.source.fullName == 'dart:core';
  }

  Set<String> resolveAll(DartType type) {
    final imports = <String>{};
    imports.add(resolve(type.element));
    imports.addAll(_checkForParameterizedTypes(type));
    return imports..removeWhere((element) => element == null);
  }

  Set<String> _checkForParameterizedTypes(DartType typeToCheck) {
    final imports = <String>{};
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        imports.add(resolve(type.element));
        imports.addAll(_checkForParameterizedTypes(type));
      }
    }
    return imports;
  }
}
