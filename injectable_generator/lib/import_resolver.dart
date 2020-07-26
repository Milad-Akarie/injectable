import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable_generator/dependency_config.dart';
import 'package:path/path.dart' as p;

abstract class TypeResolver {
  String resolveImport(Element element);

  ImportableType resolveType(DartType type);

//  factory TypeResolver(List<LibraryElement> libs) => TypeResolverImpl._(libs);

  static String relative(String path, Uri to) {
    var fileUri = Uri.parse(path);
    var libName = to.pathSegments.first;
    if ((to.scheme == 'package' && fileUri.scheme == 'package' && fileUri.pathSegments.first == libName) ||
        (to.scheme == 'asset' && fileUri.scheme != 'package')) {
      if (fileUri.path == to.path) {
        return fileUri.pathSegments.last;
      } else {
        return p.posix.relative(fileUri.path, from: to.path).replaceFirst('../', '');
      }
    } else {
      return path;
    }
  }

  static String normalizeAssetImports(String path) {
    var fileUri = Uri.parse(path);
    if (fileUri.scheme == "asset") {
      return "/${fileUri.path}";
    }
    return path;
  }
}

class TypeResolverImpl extends TypeResolver {
  final List<LibraryElement> libs;

  TypeResolverImpl(this.libs);

  String resolveImport(Element element) {
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element)) {
      return null;
    }

    for (var lib in libs) {
      if (lib.source != null && !_isCoreDartType(lib) && lib.exportNamespace.definedNames.values.contains(element)) {
        return lib.identifier;
      }
    }
    return null;
  }

  bool _isCoreDartType(Element element) {
    return element.source.fullName == 'dart:core';
  }

  Iterable<ImportableType> _resolveTypeArguments(DartType typeToCheck) {
    final importableTypes = <ImportableType>[];
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        importableTypes.add(ImportableType(
          name: type.element.name,
          import: resolveImport(type.element),
          typeArguments: _resolveTypeArguments(type),
        ));
      }
    }
    return importableTypes;
  }

  @override
  ImportableType resolveType(DartType type) {
    return ImportableType(
      name: type.element.name,
      import: resolveImport(type.element),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
