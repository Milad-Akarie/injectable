import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable_generator/dependency_config.dart';
import 'package:path/path.dart' as p;

abstract class ImportableTypeResolver {
  String resolveImport(Element element);

  ImportableType resolveType(DartType type);

  static Set<ImportableType> resolvePrefixes(Set<ImportableType> importableTypes) {
    var registeredImports = <ImportableType>{};
    var importsWithPrefixes = <String, ImportableType>{};
    for (var iType in importableTypes.where((e) => e?.import != null)) {
      if (registeredImports.any((e) => e.name == iType.name)) {
        var prefix = Uri.parse(iType.import).pathSegments.first;
        var prefixesWithSameNameCount = importsWithPrefixes.values.where((e) => e.prefix.startsWith(prefix)).length;
        prefix += (prefixesWithSameNameCount > 0 ? prefixesWithSameNameCount.toString() : '');
        importsWithPrefixes[iType.import] = iType.copyWith(prefix: prefix);
        registeredImports.add(iType);
      } else {
        registeredImports.add(iType);
      }
    }
    return importableTypes
        .where((e) => e.import != null)
        .map((e) => importsWithPrefixes[e.import] == null ? e : e.copyWith(prefix: importsWithPrefixes[e.import].prefix))
        .toSet();
  }

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

  static String resolveAssetImports(String path) {
    var fileUri = Uri.parse(path);
    if (fileUri.scheme == "asset") {
      return "/${fileUri.path}";
    }
    return path;
  }
}

class ImportableTypeResolverImpl extends ImportableTypeResolver {
  final List<LibraryElement> libs;

  ImportableTypeResolverImpl(this.libs);

  String resolveImport(Element element) {
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element)) {
      return null;
    }

    for (var lib in libs) {
      if (lib.source != null &&
          !_isCoreDartType(lib) &&
          lib.exportNamespace.definedNames.values.contains(element)) {
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
        if (type.element is TypeParameterElement) {
          importableTypes.add(ImportableType(name: 'dynamic'));
        } else {
          importableTypes.add(ImportableType(
            name: type.element.name,
            import: resolveImport(type.element),
            typeArguments: _resolveTypeArguments(type),
          ));
        }
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
