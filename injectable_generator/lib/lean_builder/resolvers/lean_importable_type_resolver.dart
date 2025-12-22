import 'package:collection/collection.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';
import 'package:lean_builder/type.dart';
import 'package:path/path.dart' as p;

abstract class LeanTypeResolver {
  Set<String> resolveImports(DartType? type);

  ImportableType resolveType(DartType type);

  ImportableType resolveFunctionType(
    FunctionType function, [
    ExecutableElement? executableElement,
  ]);

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

class LeanTypeResolverImpl extends LeanTypeResolver {
  final Resolver _resolver;
  LeanTypeResolverImpl(this._resolver);

  @override
  Set<String> resolveImports(DartType? type) {
    if (type == null || type is! NamedDartType) {
      return {};
    }
    final uri = _resolver.uriForAsset(type.declarationRef.providerId);

    // return early if the element is from core dart library
    if (_isCoreDartType(uri)) return {};

    if (uri.scheme == 'dart' && uri.pathSegments.length > 1) {
      return {'dart:${uri.pathSegments.first}'};
    }
    if (uri.scheme == 'asset') {
      return {_assetToPackage(uri)};
    }

    return {'$uri'};
  }

  bool _isCoreDartType(Uri uri) {
    return uri.scheme == 'dart' && uri.pathSegments.firstOrNull == 'core';
  }

  String _assetToPackage(Uri uri) {
    if (uri.scheme == 'asset') {
      final validSegments = <String>[];
      for (var i = 0; i < uri.pathSegments.length; i++) {
        if (uri.pathSegments[i] == 'lib') {
          if (i > 0 && i + 1 < uri.pathSegments.length) {
            validSegments.add(uri.pathSegments[i - 1]);
            validSegments.addAll(uri.pathSegments.sublist(i + 1));
            return 'package:${validSegments.join('/')}';
          }
          break;
        }
      }
    }
    return uri.toString();
  }

  @override
  ImportableType resolveFunctionType(
    FunctionType function, [
    ExecutableElement? executableElement,
  ]) {
    if (executableElement == null) {
      throw 'Can not resolve function type \nTry using an alias e.g typedef MyFunction = ${function.name};';
    }
    var functionName = function.name ?? executableElement.name;
    Element? elementToImport = executableElement;
    var enclosingElement = executableElement.enclosingElement;
    String? displayName = functionName;
    if (enclosingElement != null && enclosingElement is ClassElement) {
      functionName = '${enclosingElement.name}.$displayName';
      elementToImport = enclosingElement;
    }
    final imports = [elementToImport.library.src.shortUri.toString()];
    return ImportableType(
      name: functionName,
      import: imports.firstOrNull,
      otherImports: imports.skip(1).toSet(),
      isNullable: function.isNullable,
    );
  }

  List<ImportableType> _resolveTypeArguments(DartType typeToCheck) {
    final importableTypes = <ImportableType>[];
    if (typeToCheck is RecordType) {
      for (final recordField in [
        ...typeToCheck.positionalFields,
        ...typeToCheck.namedFields,
      ]) {
        final imports = resolveImports(recordField.type);
        importableTypes.add(
          ImportableType(
            name: recordField.type.name ?? 'void',
            import: imports.firstOrNull,
            otherImports: imports.skip(1).toSet(),
            isNullable: recordField.type.isNullable,
            typeArguments: _resolveTypeArguments(recordField.type),
            nameInRecord: recordField is RecordTypeNamedField
                ? recordField.name
                : null,
          ),
        );
      }
    } else if (typeToCheck is ParameterizedType) {
      final typeArguments = [
        ...typeToCheck.typeArguments,
      ];
      for (DartType type in typeArguments) {
        final imports = resolveImports(type);
        if (type is RecordType) {
          importableTypes.add(
            ImportableType.record(
              name: type.name ?? type.element?.name ?? 'void',
              import: imports.firstOrNull,
              otherImports: imports.skip(1).toSet(),
              isNullable: type.isNullable,
              typeArguments: _resolveTypeArguments(type),
            ),
          );
        } else if (type is TypeParameterType) {
          importableTypes.add(ImportableType(name: 'dynamic'));
        } else {
          importableTypes.add(
            ImportableType(
              name: type.name ?? 'void',
              import: imports.firstOrNull,
              otherImports: imports.skip(1).toSet(),
              isNullable: type.isNullable,
              typeArguments: _resolveTypeArguments(type),
            ),
          );
        }
      }
    }
    return importableTypes;
  }

  @override
  ImportableType resolveType(DartType type) {
    final imports = resolveImports(type);
    if (type is RecordType) {
      return ImportableType.record(
        name: type.name ?? 'void',
        import: imports.firstOrNull,
        otherImports: imports.skip(1).toSet(),
        isNullable: type.isNullable,
        typeArguments: _resolveTypeArguments(type),
      );
    }
    return ImportableType(
      name: type.name ?? 'void',
      isNullable: type.isNullable,
      import: imports.firstOrNull,
      otherImports: imports.skip(1).toSet(),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
