// holds extracted data from annotation & element
// to be used later when generating the register function

class DependencyConfig {
  String type;
  List<String> imports = [];
  List<InjectedDependency> dependencies = [];
  int injectableType;
  String instanceName;
  bool signalsReady;
  String typeImpl;
  String environment;
  String initializerName;
  String constructorName;
  bool isAsync;
  List<String> dependsOn;
  bool preResolve;

  bool isAbstract = false;
  bool isModuleMethod = false;
  // String name;
  String moduleName;

  DependencyConfig();

  DependencyConfig.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    typeImpl = json['typeImpl'];
    instanceName = json['instanceName'];
    signalsReady = json['signalsReady'];
    initializerName = json['initializerName'] ?? '';
    constructorName = json['constructorName'] ?? '';

    isAsync = json['isAsync'] ?? false;
    preResolve = json['preResolve'] ?? preResolve;
    imports = json['imports']?.cast<String>();
    dependsOn = json['dependsOn']?.cast<String>() ?? [];
    if (json['dependencies'] != null) {
      json['dependencies'].forEach((v) {
        dependencies.add(InjectedDependency.fromJson(v));
      });
    }

    injectableType = json['injectableType'];
    environment = json['environment'];

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
        "dependencies": dependencies.map((v) => v.toJson()).toList(),
        if (instanceName != null) "instanceName": instanceName,
        if (signalsReady != null) "signalsReady": signalsReady,
        if (environment != null) "environment": environment,
        if (initializerName != null) "initializerName": initializerName,
        if (constructorName != null) "constructorName": constructorName,
        if (isAbstract != null) 'isAbstract': isAbstract,
        if (isModuleMethod != null) 'isModuleMethod': isModuleMethod,
        if (moduleName != null) 'moduleName': moduleName,
      };

  Set<String> get allImports => {
        ...imports.where((i) => i != null),
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

class RegisterModuleItem {
  bool isAbstract = false;
  bool isMethod = false;
  String name;
  String moduleName;
  String import;
  Map params = {};

  RegisterModuleItem();

  RegisterModuleItem.fromJson(Map<String, dynamic> json) {
    isAbstract = json['isAbstract'] ?? false;
    isMethod = json['isMethod'] ?? false;
    name = json['name'];
    moduleName = json['moduleName'];
    import = json['import'];
    params = json['params'];
  }

  Map<String, dynamic> toJson() => {
        'isAbstract': isAbstract,
        'isMethod': isMethod,
        'name': name,
        'moduleName': moduleName,
        'import': import,
        'params': params
      };
}
