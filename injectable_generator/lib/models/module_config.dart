import 'importable_type.dart';

/// Configuration for a module containing abstract dependency registrations.
class ModuleConfig {
  /// Whether the module is abstract.
  final bool isAbstract;

  /// Whether the module member is a method rather than a getter.
  final bool isMethod;

  /// The type of the module.
  final ImportableType type;

  /// The name of the initializer method.
  final String initializerName;

  /// Creates a [ModuleConfig] with the given parameters.
  const ModuleConfig({
    required this.isAbstract,
    required this.isMethod,
    required this.type,
    required this.initializerName,
  });

  /// Creates a copy of this [ModuleConfig] with the given fields replaced.
  ModuleConfig copyWith({
    bool? isAbstract,
    bool? isModuleMethod,
    ImportableType? module,
    String? initializerName,
  }) {
    if ((isAbstract == null || identical(isAbstract, this.isAbstract)) &&
        (isModuleMethod == null || identical(isModuleMethod, isMethod)) &&
        (module == null || identical(module, type)) &&
        (initializerName == null ||
            identical(initializerName, this.initializerName))) {
      return this;
    }

    return ModuleConfig(
      isAbstract: isAbstract ?? this.isAbstract,
      isMethod: isModuleMethod ?? isMethod,
      type: module ?? type,
      initializerName: initializerName ?? this.initializerName,
    );
  }

  @override
  String toString() {
    return 'ModuleConfig{isAbstract: $isAbstract, isModuleMethod: $isMethod, module: $type, initializerName: $initializerName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModuleConfig &&
          runtimeType == other.runtimeType &&
          type == other.type);

  @override
  int get hashCode => type.hashCode;

  /// Creates a [ModuleConfig] from a JSON map.
  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      isAbstract: json['isAbstract'] as bool,
      isMethod: json['isMethod'] as bool,
      type: ImportableType.fromJson(json['type']),
      initializerName: json['initializerName'] as String,
    );
  }

  /// Converts this [ModuleConfig] to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isAbstract': isAbstract,
      'isMethod': isMethod,
      'type': type.toJson(),
      'initializerName': initializerName,
    };
  }
}
