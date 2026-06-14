// coverage:ignore-file
/// Represents the different registration types for injectable dependencies.
class InjectableType {
  const InjectableType._();

  /// Factory registration - creates a new instance each time.
  static const factory = 0;

  /// Singleton registration - creates one instance eagerly.
  static const singleton = 1;

  /// Lazy singleton registration - creates one instance on first access.
  static const lazySingleton = 2;
}
