// holds extracted data from annotation & element
// to be used later when generating the register function

import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart' show ListEquality;

import 'importable_type_resolver.dart';

class DependencyConfig {
  ImportableType type;
  ImportableType typeImpl;
  List<InjectedDependency> dependencies;
  int injectableType;
  String instanceName;
  bool signalsReady;
  List<String> environments;
  String initializerName;
  String constructorName;
  bool isAsync;
  List<String> dependsOn;
  bool preResolve;
  bool isAbstract = false;
  bool isModuleMethod = false;
  ImportableType module;

  DependencyConfig({
    this.type,
    this.dependencies,
    this.injectableType,
    this.instanceName,
    this.signalsReady,
    this.typeImpl,
    this.environments,
    this.initializerName,
    this.constructorName = '',
    this.isAsync = false,
    this.dependsOn,
    this.preResolve = false,
    this.isAbstract = false,
    this.isModuleMethod,
    this.module,
  }) {
    environments ??= [];
    dependencies ??= [];
    dependsOn ??= [];
  }

  Set<ImportableType> get allImportableTypes {
    var importableTypes = <ImportableType>{};
    if (type.fold != null) {
      importableTypes.addAll(type.fold);
    }
    if (typeImpl != null) {
      importableTypes.addAll(typeImpl.fold);
    }
    if (module != null) {
      importableTypes.addAll(module.fold);
    }
    if (dependencies?.isNotEmpty == true) {
      dependencies.forEach((dep) => importableTypes.addAll(dep.type.fold));
    }
    return importableTypes;
  }

  DependencyConfig.fromJson(Map<String, dynamic> json) {
    if (json['type'] != null) {
      type = ImportableType.fromJson(json['type']);
    }

    if (json['typeImpl'] != null) {
      typeImpl = ImportableType.fromJson(json['typeImpl']);
    }

    if (json['module'] != null) {
      module = ImportableType.fromJson(json['module']);
    }

    instanceName = json['instanceName'];
    signalsReady = json['signalsReady'];
    initializerName = json['initializerName'] ?? '';
    constructorName = json['constructorName'] ?? '';
    isAsync = json['isAsync'] ?? false;
    preResolve = json['preResolve'] ?? preResolve;

    dependsOn = json['dependsOn']?.cast<String>() ?? [];
    if (json['dependencies'] != null) {
      dependencies = [];
      json['dependencies'].forEach((v) {
        dependencies.add(InjectedDependency.fromJson(v));
      });
    }

    injectableType = json['injectableType'];
    environments = json['environments']?.cast<String>() ?? [];
    isAbstract = json['isAbstract'] ?? false;
    isModuleMethod = json['isModuleMethod'] ?? false;
  }

  bool get isFromModule => module != null;

  bool get registerAsInstance => isAsync && preResolve;

  List<InjectedDependency> get positionalDeps => dependencies.where((d) => d.isPositional).toList();

  List<InjectedDependency> get namedDeps => dependencies.where((d) => !d.isPositional).toList();

  Map<String, dynamic> toJson() => {
        if (type != null) 'type': type.toJson(),
        if (typeImpl != null) 'typeImpl': typeImpl.toJson(),
        if (module != null) 'module': module.toJson(),
        "isAsync": isAsync,
        "preResolve": preResolve,
        "injectableType": injectableType,
        "dependsOn": dependsOn,
        "environments": environments,
        "dependencies": dependencies.map((v) => v.toJson()).toList(),
        if (instanceName != null) "instanceName": instanceName,
        if (signalsReady != null) "signalsReady": signalsReady,
        if (initializerName != null) "initializerName": initializerName,
        if (constructorName != null) "constructorName": constructorName,
        if (isAbstract != null) 'isAbstract': isAbstract,
        if (isModuleMethod != null) 'isModuleMethod': isModuleMethod,
      };
}

class InjectedDependency {
  ImportableType type;
  String name;
  String paramName;
  bool isFactoryParam;
  bool isPositional;

  InjectedDependency({
    this.type,
    this.name,
    this.paramName,
    this.isFactoryParam,
    this.isPositional,
  });

  InjectedDependency.fromJson(Map<String, dynamic> json) {
    name = json['name'];

    if (json['type'] != null) {
      type = ImportableType.fromJson(json['type']);
    }
    paramName = json['paramName'];
    isFactoryParam = json['isFactoryParam'];
    isPositional = json['isPositional'];
  }

  Map<String, dynamic> toJson() => {
        "isFactoryParam": isFactoryParam,
        "isPositional": isPositional,
        if (type != null) 'type': type.toJson(),
        if (name != null) "name": name,
        if (paramName != null) "paramName": paramName,
      };
}

class ImportableType {
  String import;
  String name;
  bool isNullable = false;
  List<ImportableType> typeArguments;
  String prefix;

  ImportableType({
    this.name,
    this.import,
    this.typeArguments,
    this.prefix,
    this.isNullable,
  });

  List<ImportableType> get fold {
    final list = [this];
    typeArguments?.forEach((iType) {
      list.addAll(iType.fold);
    });
    return list;
  }

  String get identity => "$import#$name";

  String fullName({bool includeTypeArgs = true, bool includePrefix = true}) {
    var namePrefix = includePrefix && prefix != null ? '$prefix.' : '';
    var typeArgs = includeTypeArgs && (typeArguments?.isNotEmpty == true)
        ? "<${typeArguments.map((e) => e.fullName(
              includePrefix: includePrefix,
              includeTypeArgs: includePrefix,
            )).join(',')}>"
        : '';
    return "$namePrefix$name$typeArgs";
  }

  String getDisplayName(Set<ImportableType> prefixedTypes, {bool includeTypeArgs = true}) {
    return prefixedTypes?.lookup(this)?.fullName(includeTypeArgs: includeTypeArgs) ??
        fullName(includeTypeArgs: includeTypeArgs);
  }

  String get importName => "'$import' ${prefix != null ? 'as $prefix' : ''}";

  ImportableType copyWith({String import, String prefix, bool isNullable}) {
    return ImportableType(
      import: import ?? this.import,
      prefix: prefix ?? this.prefix,
      isNullable: isNullable ?? this.isNullable,
      name: this.name,
      typeArguments: this.typeArguments,
    );
  }

  Reference refer([Uri targetFile]) {
    final relativeImport = targetFile == null
        ? ImportableTypeResolver.resolveAssetImports(import)
        : ImportableTypeResolver.relative(import, targetFile);

    return TypeReference((b) {
      b
        ..symbol = name
        ..url = relativeImport
        ..isNullable = isNullable;
      if (isParametrized) {
        b.types.addAll(typeArguments?.map((e) => e.refer(targetFile)));
      }
      return b;
    });
  }

  bool get isParametrized => typeArguments?.isNotEmpty == true;

  ImportableType.fromJson(Map<String, dynamic> json) {
    import = json['import'];
    name = json['name'];
    isNullable = json['isNullable'];
    if (json['typeArguments'] != null) {
      typeArguments = [];
      json['typeArguments'].forEach((v) {
        typeArguments.add(ImportableType.fromJson(v));
      });
    }
  }

  @override
  String toString() => fullName(includePrefix: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportableType &&
          runtimeType == other.runtimeType &&
          identity == other.identity &&
          isNullable == other.isNullable &&
          ListEquality().equals(typeArguments, other.typeArguments);

  @override
  int get hashCode => import.hashCode ^ isNullable.hashCode ^ name.hashCode ^ ListEquality().hash(typeArguments);

  Map<String, dynamic> toJson() => {
        'name': name,
        'import': import,
        'isNullable': isNullable,
        if (isParametrized)
          "typeArguments": typeArguments
              .map(
                (v) => v.toJson(),
              )
              .toList(),
      };
}
