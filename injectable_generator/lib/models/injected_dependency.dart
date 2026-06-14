import 'importable_type.dart';

/// Represents a dependency that is injected into a constructor or method.
class InjectedDependency {
  /// The type of the dependency.
  ImportableType type;

  /// The named instance to resolve, or null for default instance.
  String? instanceName;

  /// The parameter name in the constructor or method.
  String paramName;

  /// Whether this dependency is a factory parameter.
  bool isFactoryParam;

  /// Whether this dependency is passed as a positional parameter.
  bool isPositional;

  /// Whether this dependency is required.
  bool isRequired;

  /// Creates an [InjectedDependency] with the given parameters.
  InjectedDependency({
    required this.type,
    required this.paramName,
    this.instanceName,
    this.isFactoryParam = false,
    this.isPositional = true,
    this.isRequired = true,
  });

  @override
  String toString() {
    return 'InjectedDependency{type: $type, instanceName: $instanceName, paramName: $paramName, isFactoryParam: $isFactoryParam, isPositional: $isPositional}, isRequired: $isRequired';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InjectedDependency &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          instanceName == other.instanceName &&
          paramName == other.paramName &&
          isFactoryParam == other.isFactoryParam &&
          isRequired == other.isRequired &&
          isPositional == other.isPositional);

  @override
  int get hashCode =>
      type.hashCode ^
      instanceName.hashCode ^
      paramName.hashCode ^
      isRequired.hashCode ^
      isFactoryParam.hashCode ^
      isPositional.hashCode;

  /// Creates an [InjectedDependency] from a JSON map.
  factory InjectedDependency.fromJson(Map<String, dynamic> json) {
    return InjectedDependency(
      type: ImportableType.fromJson(json['type']),
      instanceName: json['instanceName'],
      paramName: json['paramName'],
      isFactoryParam: json['isFactoryParam'],
      isPositional: json['isPositional'],
      isRequired: json['isRequired'] ?? false,
    );
  }

  /// Converts this [InjectedDependency] to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.toJson(),
      'instanceName': instanceName,
      'paramName': paramName,
      'isFactoryParam': isFactoryParam,
      'isPositional': isPositional,
      'isRequired': isRequired,
    };
  }
}
