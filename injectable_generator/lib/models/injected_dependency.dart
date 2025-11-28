import 'importable_type.dart';

class InjectedDependency {
  ImportableType type;
  String? instanceName;
  String paramName;
  bool isFactoryParam;
  bool isPositional;

  InjectedDependency({
    required this.type,
    required this.paramName,
    this.instanceName,
    this.isFactoryParam = false,
    this.isPositional = true,
  });

  @override
  String toString() {
    return 'InjectedDependency{type: $type, instanceName: $instanceName, paramName: $paramName, isFactoryParam: $isFactoryParam, isPositional: $isPositional}';
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
          isPositional == other.isPositional);

  @override
  int get hashCode =>
      type.hashCode ^
      instanceName.hashCode ^
      paramName.hashCode ^
      isFactoryParam.hashCode ^
      isPositional.hashCode;

  factory InjectedDependency.fromJson(Map<String, dynamic> json) {
    return InjectedDependency(
      type: ImportableType.fromJson(json['type']),
      instanceName: json['instanceName'],
      paramName: json['paramName'],
      isFactoryParam: json['isFactoryParam'],
      isPositional: json['isPositional'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'instanceName': instanceName,
      'paramName': paramName,
      'isFactoryParam': isFactoryParam,
      'isPositional': isPositional,
    };
  }
}
