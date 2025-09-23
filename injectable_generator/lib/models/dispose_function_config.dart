import 'importable_type.dart';

class DisposeFunctionConfig {
  final bool isInstance;
  final String name;
  final ImportableType? importableType;

  const DisposeFunctionConfig({
    this.isInstance = false,
    required this.name,
    this.importableType,
  });

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isInstance': isInstance,
      'name': name,
      if (importableType != null) 'importableType': importableType!.toJson(),
    };
  }
}
