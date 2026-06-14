import 'package:collection/collection.dart';

/// Represents a type that can be imported, including its import path,
/// name, nullability, and generic type arguments.
class ImportableType {
  /// The import path for this type, or null for core types.
  final String? import;

  /// The name of the type.
  final String name;

  /// Whether this type is nullable.
  final bool isNullable;

  /// Generic type arguments for this type.
  final List<ImportableType> typeArguments;

  /// Additional import paths where this type is available.
  final Set<String>? otherImports;

  /// A unique identifier combining import path and type name.
  String get identity => "$import#$name";

  final bool _isRecordType;

  /// Whether this type is a Dart record type.
  bool get isRecordType => _isRecordType;

  /// The name of the field in a record type, if applicable.
  final String? nameInRecord;

  /// Whether this type represents a named field in a record.
  bool get isNamedRecordField => nameInRecord != null;

  /// Creates an [ImportableType] with the given parameters.
  const ImportableType({
    required this.name,
    this.import,
    this.isNullable = false,
    this.typeArguments = const [],
    this.otherImports,
    this.nameInRecord,
  }) : _isRecordType = false;

  /// Private constructor for internal use.
  const ImportableType._({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    required this._isRecordType,
    this.otherImports,
    this.nameInRecord,
  });

  /// Creates an [ImportableType] representing a Dart record type.
  const ImportableType.record({
    required this.name,
    this.import,
    this.isNullable = false,
    this.typeArguments = const [],
    this.nameInRecord,
    this.otherImports,
  }) : _isRecordType = true;

  /// Returns all import paths where this type is available.
  Set<String?> get allImports => {import, ...?otherImports};

  @override
  String toString() {
    if (typeArguments.isNotEmpty) {
      return '$name<${typeArguments.map((e) => e.toString())}>';
    } else {
      return name;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportableType &&
          runtimeType == other.runtimeType &&
          allImports.intersection(other.allImports).isNotEmpty &&
          name == other.name &&
          isNullable == other.isNullable &&
          nameInRecord == other.nameInRecord &&
          _isRecordType == other._isRecordType &&
          ListEquality().equals(typeArguments, other.typeArguments));

  @override
  int get hashCode =>
      SetEquality().hash(allImports) ^
      name.hashCode ^
      isNullable.hashCode ^
      ListEquality().hash(typeArguments) ^
      _isRecordType.hashCode ^
      nameInRecord.hashCode;

  /// Creates an [ImportableType] from a JSON map.
  factory ImportableType.fromJson(Map<String, dynamic> json) {
    List<ImportableType> typeArguments = [];
    if (json['typeArguments'] != null) {
      json['typeArguments'].forEach((v) {
        typeArguments.add(ImportableType.fromJson(v));
      });
    }
    return ImportableType._(
      import: json['import'],
      name: json['name'],
      isNullable: json['isNullable'],
      otherImports: (json['otherImports'] as List<dynamic>?)
          ?.toSet()
          .cast<String>(),
      typeArguments: typeArguments,
      isRecordType: json['isRecordType'],
      nameInRecord: json['nameInRecord'],
    );
  }

  /// Converts this [ImportableType] to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'import': import,
      'name': name,
      'isNullable': isNullable,
      'isRecordType': _isRecordType,
      'nameInRecord': nameInRecord,
      if (typeArguments.isNotEmpty)
        "typeArguments": typeArguments.map((v) => v.toJson()).toList(),
      if (otherImports?.isNotEmpty == true)
        "otherImports": otherImports?.toList(),
    };
  }
}
