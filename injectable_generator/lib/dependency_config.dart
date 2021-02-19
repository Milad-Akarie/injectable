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
  List<ImportableType> dependsOn;
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
    preResolve = json['preResolve'] ?? false;

    if (json['dependsOn'] != null) {
      dependsOn = [];
      json['dependsOn'].forEach((v) {
        dependsOn.add(ImportableType.fromJson(v));
      });
    }
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

  List<InjectedDependency> get positionalDeps => dependencies?.where((d) => d.isPositional)?.toList() ?? const [];

  List<InjectedDependency> get namedDeps => dependencies?.where((d) => !d.isPositional)?.toList() ?? const [];

  Map<String, dynamic> toJson() => {
        'type': type?.toJson(),
        'typeImpl': typeImpl?.toJson(),
        'module': module?.toJson(),
        "isAsync": isAsync,
        "preResolve": preResolve,
        "injectableType": injectableType,
        if (dependsOn != null) "dependsOn": dependsOn.map((v) => v.toJson()).toList(),
        if (environments != null) "environments": environments,
        if (dependencies != null) "dependencies": dependencies.map((v) => v.toJson()).toList(),
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
  String instanceName;
  String paramName;
  bool isFactoryParam;
  bool isPositional;

  InjectedDependency({
    this.type,
    this.instanceName,
    this.paramName,
    this.isFactoryParam,
    this.isPositional,
  });

  InjectedDependency.fromJson(Map<String, dynamic> json) {
    instanceName = json['instanceName'];
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
        if (instanceName != null) "instanceName": instanceName,
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

  String get identity => "$import#$name";

  Reference refer([Uri targetFile]) {
    final relativeImport = targetFile == null
        ? ImportableTypeResolver.resolveAssetImport(import)
        : ImportableTypeResolver.relative(import, targetFile);
    return TypeReference((b) {
      b
        ..symbol = name
        ..url = relativeImport
        ..isNullable = isNullable;
      if (isParametrized) {
        b.types.addAll(
          typeArguments?.map((e) => e.refer(targetFile)),
        );
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
  String toString() {
    return refer().accept(DartEmitter()).toString();
  }

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
