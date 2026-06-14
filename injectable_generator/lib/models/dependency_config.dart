// holds extracted data from annotation & element
// to be used later when generating the register function

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:injectable_generator/models/module_config.dart';

import '../injectable_types.dart';
import 'dispose_function_config.dart';
import 'importable_type.dart';
import 'injected_dependency.dart';

/// Configuration for a dependency extracted from annotations and elements.
///
/// This class holds all the information needed to generate registration code
/// for a single injectable dependency.
class DependencyConfig {
  /// The abstract type that this dependency is registered as.
  final ImportableType type;

  /// The concrete implementation type.
  final ImportableType typeImpl;

  /// The registration type (factory, singleton, or lazy singleton).
  final int injectableType;

  /// The dependencies required by this dependency's constructor.
  final List<InjectedDependency> dependencies;

  /// The named instance identifier, or null for default registration.
  final String? instanceName;

  /// Whether this singleton signals when it's ready.
  final bool? signalsReady;

  /// The environment keys this dependency is registered for.
  final List<String> environments;

  /// The named constructor to use, or empty string for default.
  final String constructorName;

  /// The name of a post-construct method to call after instantiation.
  final String? postConstruct;

  /// Whether this dependency is registered asynchronously.
  final bool isAsync;

  /// Whether the post-construct method returns the instance itself.
  final bool postConstructReturnsSelf;

  /// Types that this singleton depends on for readiness signaling.
  final List<ImportableType> dependsOn;

  /// Whether to pre-resolve this dependency at initialization time.
  final bool preResolve;

  /// Whether this dependency can be created as a const expression.
  final bool canBeConst;

  /// Configuration for the module this dependency comes from, if any.
  final ModuleConfig? moduleConfig;

  /// Configuration for the dispose function, if any.
  final DisposeFunctionConfig? disposeFunction;

  /// The order position for registration sorting.
  final int orderPosition;

  /// The scope this dependency belongs to, or null for root scope.
  final String? scope;

  /// Whether this factory's result should be cached.
  final bool cache;

  /// Creates a [DependencyConfig] with the given parameters.
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
    this.cache = false,
  });

  /// Creates a factory-type [DependencyConfig] for testing purposes.
  factory DependencyConfig.factory(
    String type, {
    String? typeImpl,
    List<String> deps = const [],
    List<String> envs = const [],
    int order = 0,
    bool cache = false,
  }) {
    return DependencyConfig(
      type: ImportableType(name: type),
      typeImpl: ImportableType(name: typeImpl ?? type),
      environments: envs,
      orderPosition: order,
      cache: cache,
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

  /// Creates a singleton-type [DependencyConfig] for testing purposes.
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
      injectableType: lazy
          ? InjectableType.lazySingleton
          : InjectableType.singleton,
      environments: envs,
      orderPosition: order,
      cache: false,
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
          cache == other.cache &&
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
      cache.hashCode ^
      postConstructReturnsSelf.hashCode ^
      scope.hashCode;

  /// Returns a hash code based on fields that identify this dependency uniquely.
  late final int identityHash =
      type.identity.hashCode ^
      typeImpl.identity.hashCode ^
      injectableType.hashCode ^
      instanceName.hashCode ^
      orderPosition.hashCode ^
      scope.hashCode ^
      const ListEquality().hash(dependencies) ^
      const ListEquality().hash(dependsOn) ^
      const ListEquality().hash(environments);

  /// Creates a [DependencyConfig] from a JSON map.
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
      cache: (json['cache'] as bool?) ?? false,
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

  /// Converts this [DependencyConfig] to a JSON map.
  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    'typeImpl': typeImpl.toJson(),
    "isAsync": isAsync,
    "postConstructReturnsSelf": postConstructReturnsSelf,
    "preResolve": preResolve,
    "canBeConst": canBeConst,
    "injectableType": injectableType,
    if (moduleConfig != null) 'moduleConfig': moduleConfig!.toJson(),
    if (disposeFunction != null) 'disposeFunction': disposeFunction!.toJson(),
    "dependsOn": dependsOn.map((v) => v.toJson()).toList(),
    "environments": environments,
    "dependencies": dependencies.map((v) => v.toJson()).toList(),
    if (instanceName != null) "instanceName": instanceName,
    "cache": cache,
    if (signalsReady != null) "signalsReady": signalsReady,
    "constructorName": constructorName,
    if (postConstruct != null) "postConstruct": postConstruct,
    "orderPosition": orderPosition,
    if (scope != null) "scope": scope,
  };

  /// Whether this dependency comes from a module.
  bool get isFromModule => moduleConfig != null;

  /// Returns positional dependencies (non-named parameters).
  List<InjectedDependency> get positionalDependencies =>
      dependencies.where((d) => d.isPositional).toList();

  /// Returns named dependencies (named parameters).
  List<InjectedDependency> get namedDependencies =>
      dependencies.where((d) => !d.isPositional).toList();
}
