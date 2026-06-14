import 'importable_type.dart';

/// Configuration for a dispose function on a singleton.
class DisposeFunctionConfig {
  /// Whether the dispose function is an instance method.
  final bool isInstance;

  /// The name of the dispose function.
  final String name;

  /// The importable type for external dispose functions, if applicable.
  final ImportableType? importableType;

  /// Creates a [DisposeFunctionConfig] with the given parameters.
  const DisposeFunctionConfig({
    this.isInstance = false,
    required this.name,
    this.importableType,
  });

  /// Creates a copy of this [DisposeFunctionConfig] with the given fields replaced.
  DisposeFunctionConfig copyWith({
    bool? isInstance,
    String? name,
    ImportableType? importableType,
  }) {
    if ((isInstance == null || identical(isInstance, this.isInstance)) &&
        (name == null || identical(name, this.name)) &&
        (importableType == null ||
            identical(importableType, this.importableType))) {
      return this;
    }

    return DisposeFunctionConfig(
      isInstance: isInstance ?? this.isInstance,
      name: name ?? this.name,
      importableType: importableType ?? this.importableType,
    );
  }

  @override
  String toString() {
    return 'DisposeFunctionConfig{isInstance: $isInstance, name: $name, importableType: $importableType}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisposeFunctionConfig &&
          runtimeType == other.runtimeType &&
          isInstance == other.isInstance &&
          name == other.name &&
          importableType == other.importableType);

  @override
  int get hashCode =>
      isInstance.hashCode ^ name.hashCode ^ importableType.hashCode;

  /// Creates a [DisposeFunctionConfig] from a JSON map.
  factory DisposeFunctionConfig.fromJson(Map<String, dynamic> json) {
    ImportableType? disposeFunction;

    if (json['importableType'] != null) {
      disposeFunction = ImportableType.fromJson(json['importableType']);
    }
    return DisposeFunctionConfig(
      isInstance: json['isInstance'] as bool,
      name: json['name'] as String,
      importableType: disposeFunction,
    );
  }

  /// Converts this [DisposeFunctionConfig] to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isInstance': isInstance,
      'name': name,
      if (importableType != null) 'importableType': importableType!.toJson(),
    };
  }
}
