import 'package:injectable_generator/models/importable_type.dart';

/// Configuration for an external package module.
class ExternalModuleConfig {
  /// The module type.
  final ImportableType module;

  /// The scope for this module, if applicable.
  final String? scope;

  /// Creates an [ExternalModuleConfig] with the given parameters.
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
