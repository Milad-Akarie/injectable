// holds extracted data from annotation & element
// to be used later when generating the register function

class DependencyConfig {
  String type;
  List<String> imports;
  List<InjectedDependency> dependencies;
  int injectableType;
  String instanceName;
  bool signalsReady;
  String typeImpl;
  List<String> environments;
  String initializerName;
  String constructorName;
  bool isAsync;
  List<String> dependsOn;
  bool preResolve;
  bool isAbstract = false;
  bool isModuleMethod = false;
  String moduleName;

  DependencyConfig({
    this.type,
    this.imports,
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
    this.moduleName,
  }) {
    environments ??= [];
    imports ??= [];
    dependencies ??= [];
    dependsOn ??= [];
  }

  DependencyConfig.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    typeImpl = json['typeImpl'];
    instanceName = json['instanceName'];
    signalsReady = json['signalsReady'];
    initializerName = json['initializerName'] ?? '';
    constructorName = json['constructorName'] ?? '';

    isAsync = json['isAsync'] ?? false;
    preResolve = json['preResolve'] ?? preResolve;
    imports = json['imports']?.cast<String>() ?? [];
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
    moduleName = json['moduleName'];
  }

  bool get isFromModule => moduleName != null;

  bool get registerAsInstance => isAsync && preResolve;

  Map<String, dynamic> toJson() => {
        "type": type,
        "typeImpl": typeImpl,
        "isAsync": isAsync,
        "preResolve": preResolve,
        "injectableType": injectableType,
        "imports": imports.toSet().toList(),
        "dependsOn": dependsOn,
        "environments": environments,
        "dependencies": dependencies.map((v) => v.toJson()).toList(),
        if (instanceName != null) "instanceName": instanceName,
        if (signalsReady != null) "signalsReady": signalsReady,
        if (initializerName != null) "initializerName": initializerName,
        if (constructorName != null) "constructorName": constructorName,
        if (isAbstract != null) 'isAbstract': isAbstract,
        if (isModuleMethod != null) 'isModuleMethod': isModuleMethod,
        if (moduleName != null) 'moduleName': moduleName,
      };
}

class InjectedDependency {
  String type;
  String name;
  String paramName;
  bool isFactoryParam;
  bool isPositional;

  InjectedDependency(
      {this.type,
      this.name,
      this.paramName,
      this.isFactoryParam,
      this.isPositional});

  InjectedDependency.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
    paramName = json['paramName'];
    isFactoryParam = json['isFactoryParam'];
    isPositional = json['isPositional'];
  }

  Map<String, dynamic> toJson() => {
        "type": type,
        "isFactoryParam": isFactoryParam,
        "isPositional": isPositional,
        if (name != null) "name": name,
        if (paramName != null) "paramName": paramName,
      };
}
