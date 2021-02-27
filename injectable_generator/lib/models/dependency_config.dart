// holds extracted data from annotation & element
// to be used later when generating the register function

import 'package:injectable_generator/models/module_config.dart';

import 'dispose_function_config.dart';
import 'importable_type.dart';
import 'injected_dependency.dart';

class DependencyConfig {
  final ImportableType type;
  final ImportableType typeImpl;
  final int injectableType;

  final List<InjectedDependency> dependencies;
  final String? instanceName;
  final bool? signalsReady;
  final List<String> environments;
  final String? constructorName;
  final bool isAsync;
  final List<ImportableType>? dependsOn;
  final bool preResolve;
  final ModuleConfig? moduleConfig;
  final DisposeFunctionConfig? disposeFunction;

  const DependencyConfig({
    required this.type,
    required this.typeImpl,
    required this.injectableType,
    this.dependencies = const [],
    this.instanceName,
    this.signalsReady,
    this.environments = const [],
    this.constructorName,
    this.isAsync = false,
    this.dependsOn = const [],
    this.preResolve = false,
    this.moduleConfig,
    this.disposeFunction,
  });

  @override
  String toString() {
    return 'DependencyConfig{type: $type, typeImpl: $typeImpl, dependencies: $dependencies, injectableType: $injectableType, instanceName: $instanceName, signalsReady: $signalsReady, environments: $environments, constructorName: $constructorName, isAsync: $isAsync, dependsOn: $dependsOn, preResolve: $preResolve, moduleConfig: $moduleConfig}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DependencyConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          typeImpl == other.typeImpl &&
          dependencies == other.dependencies &&
          injectableType == other.injectableType &&
          instanceName == other.instanceName &&
          signalsReady == other.signalsReady &&
          environments == other.environments &&
          constructorName == other.constructorName &&
          isAsync == other.isAsync &&
          dependsOn == other.dependsOn &&
          preResolve == other.preResolve &&
          disposeFunction == other.disposeFunction &&
          moduleConfig == other.moduleConfig);

  @override
  int get hashCode =>
      type.hashCode ^
      typeImpl.hashCode ^
      dependencies.hashCode ^
      injectableType.hashCode ^
      instanceName.hashCode ^
      signalsReady.hashCode ^
      environments.hashCode ^
      constructorName.hashCode ^
      isAsync.hashCode ^
      dependsOn.hashCode ^
      preResolve.hashCode ^
      disposeFunction.hashCode ^
      moduleConfig.hashCode;

  factory DependencyConfig.fromJson(Map<dynamic, dynamic> json) {
    ModuleConfig? moduleConfig;
    DisposeFunctionConfig? disposeFunction;

    List<ImportableType> dependsOn = [];
    List<InjectedDependency> dependencies = [];

    if (json['moduleConfig'] != null) {
      moduleConfig = ModuleConfig.fromJson(json['moduleConfig']);
    }

    if (json['disposeFunction'] != null) {
      disposeFunction = DisposeFunctionConfig.fromJson(json['disposeFunction']);
    }

    if (json['dependencies'] != null) {
      json['dependencies'].forEach((v) {
        dependencies.add(InjectedDependency.fromJson(v));
      });
    }

    if (json['dependsOn'] != null) {
      json['dependsOn'].forEach((v) {
        dependsOn.add(ImportableType.fromJson(v));
      });
    }

    return DependencyConfig(
      type: ImportableType.fromJson(json['type']),
      typeImpl: ImportableType.fromJson(json['typeImpl']),
      dependencies: dependencies,
      injectableType: json['injectableType'] as int,
      instanceName: json['instanceName'] as String,
      signalsReady: json['signalsReady'] as bool,
      environments: json['environments']?.cast<String>(),
      constructorName: json['constructorName'] as String,
      isAsync: json['isAsync'] as bool,
      dependsOn: dependsOn,
      preResolve: json['preResolve'] as bool,
      moduleConfig: moduleConfig,
      disposeFunction: disposeFunction,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'typeImpl': typeImpl.toJson(),
        "isAsync": isAsync,
        "preResolve": preResolve,
        "injectableType": injectableType,
        if (moduleConfig != null) 'moduleConfig': moduleConfig!.toJson(),
        if (disposeFunction != null)
          'disposeFunction': disposeFunction!.toJson(),
        if (dependsOn != null)
          "dependsOn": dependsOn!.map((v) => v.toJson()).toList(),
        "environments": environments,
        "dependencies": dependencies.map((v) => v.toJson()).toList(),
        if (instanceName != null) "instanceName": instanceName,
        if (signalsReady != null) "signalsReady": signalsReady,
        if (constructorName != null) "constructorName": constructorName,
      };

  bool get isFromModule => moduleConfig != null;

  List<InjectedDependency> get positionalDependencies =>
      dependencies.where((d) => d.isPositional).toList();

  List<InjectedDependency> get namedDependencies =>
      dependencies.where((d) => !d.isPositional).toList();
}
