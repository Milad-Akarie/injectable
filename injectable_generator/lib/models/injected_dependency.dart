import 'package:meta/meta.dart';

import 'importable_type.dart';

class InjectedDependency {
  ImportableType type;
  String? instanceName;
  String paramName;
  bool isFactoryParam;
  bool isPositional;

  InjectedDependency({
    required this.type,
    this.instanceName,
    required this.paramName,
    required this.isFactoryParam,
    required this.isPositional,
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
      type.hashCode ^ instanceName.hashCode ^ paramName.hashCode ^ isFactoryParam.hashCode ^ isPositional.hashCode;

  factory InjectedDependency.fromJson(Map<String, dynamic> json) {
    var type;
    if (json['type'] != null) {
      type = ImportableType.fromJson(json['type']);
    }
    return InjectedDependency(
      type: type,
      instanceName: json['instanceName'] as String,
      paramName: json['paramName'] as String,
      isFactoryParam: json['isFactoryParam'] as bool,
      isPositional: json['isPositional'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    // ignore: unnecessary_cast
    return {
      'type': this.type,
      'instanceName': this.instanceName,
      'paramName': this.paramName,
      'isFactoryParam': this.isFactoryParam,
      'isPositional': this.isPositional,
    } as Map<String, dynamic>;
  }
}
