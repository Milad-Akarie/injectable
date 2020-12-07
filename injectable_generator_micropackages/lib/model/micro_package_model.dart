/// Represents a micro package
class MicroPackageModuleModel {
  /// the moduleFileLocation, like package:<name>/<name>.dart
  final String moduleFileLocation;

  /// the module or package name
  final String moduleName;

  /// Name of the class that has
  /// registerModuleDependencies method and @microPackage annotation
  final String moduleClassName;

  ///Name of the method
  ///which will be called on module registration
  final String methodName;

  MicroPackageModuleModel(
      this.moduleFileLocation, this.moduleName, this.moduleClassName,{
        this.methodName = 'registerModuleDependencies'
      });

  @override
  String toString() {
    return "moduleFileLocation $moduleFileLocation \n" +
        "moduleName $moduleName \n" +
        "moduleClassName $moduleClassName";
  }

  MicroPackageModuleModel.fromJson(Map<String, dynamic> json)
      : moduleFileLocation = json['moduleFileLocation'],
        moduleName = json['moduleName'],
        moduleClassName = json['moduleClassName'],
        methodName = json['methodName'];

  Map<String, dynamic> toJson() => {
        'moduleFileLocation': moduleFileLocation,
        'moduleName': moduleName,
        'moduleClassName': moduleClassName,
        'methodName': methodName
      };
}
