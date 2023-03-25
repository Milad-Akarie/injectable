import 'package:injectable_generator/models/importable_type.dart';

class ExternalModuleConfig {
  final ImportableType module;
  final String? scope;

  const ExternalModuleConfig(this.module, [this.scope]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalModuleConfig &&
          runtimeType == other.runtimeType &&
          module == other.module &&
          scope == other.scope;

  @override
  int get hashCode => module.hashCode ^ scope.hashCode;
}
