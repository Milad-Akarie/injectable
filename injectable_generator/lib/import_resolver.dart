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
    if (element.source == null || _isCoreDartType(element)) {
      return null;
    }

    for (var lib in libs) {
      if (lib.source != null && !_isCoreDartType(lib) && lib.exportNamespace.definedNames.keys.contains(element.name)) {
        return lib.source.uri.toString();
      }
    }
    return null;
  }

  static String relative(String packagePath, String from) {
    var uri = Uri.parse(packagePath);
    var thisLibName = uri.pathSegments.first;
    if (uri.path == from) {
      return uri.pathSegments.last;
    } else if (from.startsWith(thisLibName)) {
      return p.posix.relative(uri.path, from: from).replaceFirst('../', '');
    } else {
      return packagePath;
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
