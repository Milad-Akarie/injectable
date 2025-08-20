import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/utils.dart';
import 'package:path/path.dart' as p;

abstract class ImportableTypeResolver {
  Set<String> resolveImports(Element2 element);

  ImportableType resolveType(DartType type);

  ImportableType resolveFunctionType(FunctionType function, [ExecutableElement2? executableElement]);

  static String? relative(String? path, Uri? to) {
    if (path == null || to == null) {
      return null;
    }
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
  final List<LibraryElement2> libs;

  ImportableTypeResolverImpl(this.libs);

  @override
  Set<String> resolveImports(Element2? element) {
    final imports = <String>{};
    final maybeElement = element;

    if (maybeElement == null || maybeElement.firstFragment.libraryFragment == null || _isCoreDartType(maybeElement)) {
      return imports;
    }

    // Matching element name and containing library should be unambiguous
    final elementContainingLibs = libs.where(
      (lib) => lib.exportNamespace.definedNames2.values
          .map((definedName) => (definedName.displayName, definedName.library2?.uri))
          .contains((maybeElement.displayName, maybeElement.library2?.uri)),
    );

    for (var lib in elementContainingLibs) {
      if (!_isCoreDartType(lib)) {
        imports.add(lib.uri.toString());
      }
    }
    return imports;
  }

  bool _isCoreDartType(Element2? element) {
    return element?.firstFragment.libraryFragment?.source.fullName == 'dart:core';
  }

  @override
  ImportableType resolveFunctionType(FunctionType function, [ExecutableElement2? executableElement]) {
    final functionElement = executableElement ?? function.element3 ?? function.alias?.element2;
    if (functionElement == null) {
      throw 'Can not resolve function type \nTry using an alias e.g typedef MyFunction = ${function.nameWithoutSuffix};';
    }
    final displayName = functionElement.displayName;
    var functionName = displayName;

    Element2 elementToImport = functionElement;
    var enclosingElement = functionElement.enclosingElement2;

    if (enclosingElement != null && enclosingElement is ClassElement2) {
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
    if (typeToCheck is RecordType && typeToCheck.alias == null) {
      for (final recordField in [...typeToCheck.positionalFields, ...typeToCheck.namedFields]) {
        final imports = resolveImports(recordField.type.element3);
        importableTypes.add(ImportableType(
          name: recordField.type.element3?.displayName ?? 'void',
          import: imports.firstOrNull,
          otherImports: imports.skip(1).toSet(),
          isNullable: recordField.type.nullabilitySuffix == NullabilitySuffix.question,
          typeArguments: _resolveTypeArguments(recordField.type),
          nameInRecord: recordField is RecordTypeNamedField ? recordField.name : null,
        ));
      }
    } else if (typeToCheck is ParameterizedType || typeToCheck.alias != null) {
      final typeArguments = [
        if (typeToCheck.alias != null)
          ...typeToCheck.alias!.typeArguments
        else if (typeToCheck is ParameterizedType)
          ...typeToCheck.typeArguments
      ];
      for (DartType type in typeArguments) {
        final imports = resolveImports(type.element3);
        if (type is RecordType) {
          importableTypes.add(ImportableType.record(
            name: type.element3?.displayName ?? '',
            import: imports.firstOrNull,
            otherImports: imports.skip(1).toSet(),
            isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
            typeArguments: _resolveTypeArguments(type),
          ));
        } else if (type.element3 is TypeParameterElement2) {
          importableTypes.add(ImportableType(name: 'dynamic'));
        } else {
          importableTypes.add(ImportableType(
            name: type.element3?.displayName ?? type.nameWithoutSuffix,
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
    final effectiveElement = type.alias?.element2 ?? type.element3;
    final imports = resolveImports(effectiveElement);
    if (type is RecordType && type.alias == null) {
      return ImportableType.record(
        name: effectiveElement?.displayName ?? '',
        import: imports.firstOrNull,
        otherImports: imports.skip(1).toSet(),
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        typeArguments: _resolveTypeArguments(type),
      );
    }
    return ImportableType(
      name: effectiveElement?.displayName ?? type.nameWithoutSuffix,
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      import: imports.firstOrNull,
      otherImports: imports.skip(1).toSet(),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
