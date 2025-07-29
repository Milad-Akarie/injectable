// holds extracted data from annotation & element
// to be used later when generating the register function

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:injectable_generator/models/module_config.dart';

import '../injectable_types.dart';
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
  final String? postConstruct;
  final bool isAsync;
  final bool postConstructReturnsSelf;
  final List<ImportableType> dependsOn;
  final bool preResolve;
  final bool canBeConst;
  final ModuleConfig? moduleConfig;
  final DisposeFunctionConfig? disposeFunction;
  final int orderPosition;
  final String? scope;

  DependencyConfig({
    required this.type,
    required this.typeImpl,
    this.injectableType = InjectableType.factory,
    this.dependencies = const [],
    this.instanceName,
    this.signalsReady,
    this.environments = const [],
    this.constructorName = '',
    this.isAsync = false,
    this.dependsOn = const [],
    this.preResolve = false,
    this.canBeConst = false,
    this.moduleConfig,
    this.disposeFunction,
    this.orderPosition = 0,
    this.scope,
    this.postConstructReturnsSelf = false,
    this.postConstruct,
  });

  // used for testing
  factory DependencyConfig.factory(
    String type, {
    String? typeImpl,
    List<String> deps = const [],
    List<String> envs = const [],
    int order = 0,
  }) {
    return DependencyConfig(
      type: ImportableType(name: type, import: type),
      typeImpl: ImportableType(name: typeImpl ?? type),
      environments: envs,
      orderPosition: order,
      dependencies: deps
          .map(
            (e) => InjectedDependency(
              type: ImportableType(name: e),
              paramName: e.toLowerCase(),
            ),
          )
          .toList(),
    );
  }

  // used for testing
  factory DependencyConfig.singleton(
    String type, {
    String? typeImpl,
    List<String> deps = const [],
    List<String> envs = const [],
    int order = 0,
    bool lazy = false,
  }) {
    return DependencyConfig(
      type: ImportableType(name: type),
      typeImpl: ImportableType(name: typeImpl ?? type),
      injectableType:
          lazy ? InjectableType.lazySingleton : InjectableType.singleton,
      environments: envs,
      orderPosition: order,
      dependencies: deps
          .map(
            (e) => InjectedDependency(
              type: ImportableType(name: e),
              paramName: e.toLowerCase(),
            ),
          )
          .toList(),
    );
  }

  @override
  String toString() {
    final prettyJson = JsonEncoder.withIndent(' ').convert(toJson());
    return 'DependencyConfig $prettyJson';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DependencyConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          typeImpl == other.typeImpl &&
          ListEquality().equals(dependencies, other.dependencies) &&
          injectableType == other.injectableType &&
          instanceName == other.instanceName &&
          signalsReady == other.signalsReady &&
          ListEquality().equals(environments, other.environments) &&
          constructorName == other.constructorName &&
          isAsync == other.isAsync &&
          ListEquality().equals(dependsOn, other.dependsOn) &&
          preResolve == other.preResolve &&
          canBeConst == other.canBeConst &&
          disposeFunction == other.disposeFunction &&
          scope == other.scope &&
          moduleConfig == other.moduleConfig &&
          postConstruct == other.postConstruct &&
          postConstructReturnsSelf == other.postConstructReturnsSelf &&
          orderPosition == other.orderPosition);

  @override
  int get hashCode =>
      type.hashCode ^
      typeImpl.hashCode ^
      ListEquality().hash(dependencies) ^
      injectableType.hashCode ^
      instanceName.hashCode ^
      signalsReady.hashCode ^
      ListEquality().hash(environments) ^
      constructorName.hashCode ^
      isAsync.hashCode ^
      ListEquality().hash(dependsOn) ^
      preResolve.hashCode ^
      disposeFunction.hashCode ^
      moduleConfig.hashCode ^
      canBeConst.hashCode ^
      orderPosition.hashCode ^
      postConstruct.hashCode ^
      postConstructReturnsSelf.hashCode ^
      scope.hashCode;

  late final int identityHash = type.identity.hashCode ^
      typeImpl.identity.hashCode ^
      injectableType.hashCode ^
      instanceName.hashCode ^
      orderPosition.hashCode ^
      scope.hashCode ^
      const ListEquality().hash(dependencies) ^
      const ListEquality().hash(dependsOn) ^
      const ListEquality().hash(environments);

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
      injectableType: json['injectableType'],
      instanceName: json['instanceName'],
      signalsReady: json['signalsReady'],
      environments: json['environments']?.cast<String>(),
      constructorName: json['constructorName'],
      postConstruct: json['postConstruct'],
      isAsync: json['isAsync'] as bool,
      canBeConst: json['canBeConst'] as bool,
      dependsOn: dependsOn,
      preResolve: json['preResolve'] as bool,
      postConstructReturnsSelf: json['postConstructReturnsSelf'] as bool,
      moduleConfig: moduleConfig,
      disposeFunction: disposeFunction,
      orderPosition: json['orderPosition'] as int,
      scope: json['scope'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'typeImpl': typeImpl.toJson(),
        "isAsync": isAsync,
        "postConstructReturnsSelf": postConstructReturnsSelf,
        "preResolve": preResolve,
        "canBeConst": canBeConst,
        "injectableType": injectableType,
        if (moduleConfig != null) 'moduleConfig': moduleConfig!.toJson(),
        if (disposeFunction != null)
          'disposeFunction': disposeFunction!.toJson(),
        "dependsOn": dependsOn.map((v) => v.toJson()).toList(),
        "environments": environments,
        "dependencies": dependencies.map((v) => v.toJson()).toList(),
        if (instanceName != null) "instanceName": instanceName,
        if (signalsReady != null) "signalsReady": signalsReady,
        if (constructorName != null) "constructorName": constructorName,
        if (postConstruct != null) "postConstruct": postConstruct,
        "orderPosition": orderPosition,
        if (scope != null) "scope": scope,
      };

  bool get isFromModule => moduleConfig != null;

  List<InjectedDependency> get positionalDependencies =>
      dependencies.where((d) => d.isPositional).toList();

  List<InjectedDependency> get namedDependencies =>
      dependencies.where((d) => !d.isPositional).toList();
}
