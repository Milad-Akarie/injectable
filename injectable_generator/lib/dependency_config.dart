// holds extracted data from annotation & element
// to be used later when generating the register function

class DependencyConfig {
  String type;
  List<String> imports = [];
  List<InjectedDependency> dependencies = [];
  int injectableType;
  String instanceName;
  bool signalsReady;
  String bindTo;
  String environment;
  String constructorName;

  DependencyConfig();

  DependencyConfig.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    bindTo = json['bindTo'];
    instanceName = json['instanceName'];
    signalsReady = json['signalsReady'];
    constructorName = json['constructorName'];

    imports = json['imports'].cast<String>();
    if (json['dependencies'] != null) {
      json['dependencies'].forEach((v) {
        dependencies.add(InjectedDependency.fromJson(v));
      });
    }

    injectableType = json['injectableType'];
    environment = json['environment'];
  }

  Map<String, dynamic> toJson() => {
        "type": type,
        "bindTo": bindTo,
        "injectableType": injectableType,
        "imports": imports.toSet().toList(),
        "dependencies": dependencies.map((v) => v.toJson()).toList(),
        "instanceName": instanceName,
        "signalsReady": signalsReady,
        "environment": environment,
        "constructorName": constructorName
      };

  Set<String> get allImports => {
        ...imports.where((i) => i != null),
        ...dependencies.map((dep) => dep.import).where((i) => i != null),
      };
}

class InjectedDependency {
  String type;
  String name;
  String import;
  String paramName;

  InjectedDependency({this.type, this.name, this.import, this.paramName});
  InjectedDependency.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
    import = json['import'];
    paramName = json['paramName'];
  }

  Map<String, dynamic> toJson() => {
        "type": type,
        "import": import,
        if (name != null) "name": name,
        if (paramName != null) "paramName": paramName,
      };
}
