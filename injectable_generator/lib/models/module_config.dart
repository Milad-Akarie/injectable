import 'package:meta/meta.dart';

import 'importable_type.dart';

class ModuleConfig {
  final bool isAbstract;
  final bool isMethod;
  final ImportableType type;
  final String initializerName;

  const ModuleConfig({
    @required this.isAbstract,
    @required this.isMethod,
    @required this.type,
    @required this.initializerName,
  });

  ModuleConfig copyWith({
    bool isAbstract,
    bool isModuleMethod,
    ImportableType module,
    String initializerName,
  }) {
    if ((isAbstract == null || identical(isAbstract, this.isAbstract)) &&
        (isModuleMethod == null || identical(isModuleMethod, this.isMethod)) &&
        (module == null || identical(module, this.type)) &&
        (initializerName == null || identical(initializerName, this.initializerName))) {
      return this;
    }

    return ModuleConfig(
      isAbstract: isAbstract ?? this.isAbstract,
      isMethod: isModuleMethod ?? this.isMethod,
      type: module ?? this.type,
      initializerName: initializerName ?? this.initializerName,
    );
  }

  @override
  String toString() {
    return 'ModuleConfig{isAbstract: $isAbstract, isModuleMethod: $isMethod, module: $type, initializerName: $initializerName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ModuleConfig && runtimeType == other.runtimeType && type == other.type);

  @override
  int get hashCode => type.hashCode;

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    ImportableType type;
    if (json['type'] != null) {
      type = ImportableType.fromJson(json['type']);
    }
    return ModuleConfig(
      isAbstract: json['isAbstract'] as bool,
      isMethod: json['isMethod'] as bool,
      type: type,
      initializerName: json['initializerName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    // ignore: unnecessary_cast
    return {
      'isAbstract': this.isAbstract,
      'isMethod': this.isMethod,
      'type': this.type,
      'initializerName': this.initializerName,
    } as Map<String, dynamic>;
  }
}
