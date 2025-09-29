import 'package:collection/collection.dart';

class ImportableType {
  final String? import;
  final String name;
  final bool isNullable;
  final List<ImportableType> typeArguments;
  final Set<String>? otherImports;

  String get identity => "$import#$name";

  final bool _isRecordType;

  bool get isRecordType => _isRecordType;

  /// the name of the field in the record
  final String? nameInRecord;

  /// whether the type is for a named record field
  bool get isNamedRecordField => nameInRecord != null;

  const ImportableType({
    required this.name,
    this.import,
    this.isNullable = false,
    this.typeArguments = const [],
    this.otherImports,
    this.nameInRecord,
  }) : _isRecordType = false;

  const ImportableType._({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    required bool isRecordType,
    this.otherImports,
    this.nameInRecord,
  }) : _isRecordType = isRecordType;

  const ImportableType.record({
    required this.name,
    this.import,
    this.isNullable = false,
    this.typeArguments = const [],
    this.nameInRecord,
    this.otherImports,
  }) : _isRecordType = true;

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
