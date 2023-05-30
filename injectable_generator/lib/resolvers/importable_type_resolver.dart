import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:path/path.dart' as p;

abstract class ImportableTypeResolver {
  Set<String> resolveImports(Element element);

  ImportableType resolveType(DartType type);

  ImportableType resolveFunctionType(FunctionType function,
      [ExecutableElement? executableElement]);

  static String? relative(String? path, Uri? to) {
    if (path == null || to == null) {
      return null;
    }
    var fileUri = Uri.parse(path);
    var libName = to.pathSegments.first;
    if ((to.scheme == 'package' &&
            fileUri.scheme == 'package' &&
            fileUri.pathSegments.first == libName) ||
        (to.scheme == 'asset' && fileUri.scheme != 'package')) {
      if (fileUri.path == to.path) {
        return fileUri.pathSegments.last;
      } else {
        return p.posix
            .relative(fileUri.path, from: to.path)
            .replaceFirst('../', '');
      }
    } else {
      return path;
    }
  }

  static String? resolveAssetImport(String? path) {
    if (path == null) {
      return null;
    }
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

  @override
  Set<String> resolveImports(Element? element) {
    final imports = <String>{};
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element)) {
      return imports;
    }
    libs.where((e) => e.exportNamespace.definedNames.values.contains(element));
    for (var lib in libs) {
      if (!_isCoreDartType(lib) &&
          lib.exportNamespace.definedNames.values.contains(element)) {
        imports.add(lib.identifier);
      }
    }
    return imports;
  }

  bool _isCoreDartType(Element? element) {
    return element?.source?.fullName == 'dart:core';
  }

  @override
  ImportableType resolveFunctionType(FunctionType function,
      [ExecutableElement? executableElement]) {
    final functionElement =
        executableElement ?? function.element ?? function.alias?.element;
    if (functionElement == null) {
      throw 'Can not resolve function type \nTry using an alias e.g typedef MyFunction = ${function.getDisplayString(withNullability: false)};';
    }
    final displayName = functionElement.displayName;
    var functionName = displayName;

    Element elementToImport = functionElement;
    var enclosingElement = functionElement.enclosingElement;

    if (enclosingElement != null && enclosingElement is ClassElement) {
      functionName = '${enclosingElement.displayName}.$displayName';
      elementToImport = enclosingElement;
    }
    final imports = resolveImports(elementToImport);
    return ImportableType(
      name: functionName,
      import: imports.firstOrNull,
      otherImports: imports.skip(1).toSet(),
      isNullable: function.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  List<ImportableType> _resolveTypeArguments(DartType typeToCheck) {
    final importableTypes = <ImportableType>[];
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        if (type.element is TypeParameterElement) {
          importableTypes.add(ImportableType(name: 'dynamic'));
        } else {
          final imports = resolveImports(type.element);
          importableTypes.add(ImportableType(
            name: type.element?.name ??
                type.getDisplayString(withNullability: false),
            import: imports.firstOrNull,
            otherImports: imports.skip(1).toSet(),
            isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
            typeArguments: _resolveTypeArguments(type),
          ));
        }
      }
    }
    return importableTypes;
  }

  @override
  ImportableType resolveType(DartType type) {
    final imports = resolveImports(type.element);
    return ImportableType(
      name: type.element?.name ?? type.getDisplayString(withNullability: false),
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      import: imports.firstOrNull,
      otherImports: imports.skip(1).toSet(),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
