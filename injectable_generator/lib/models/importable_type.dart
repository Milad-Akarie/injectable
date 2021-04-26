import 'package:collection/collection.dart';

class ImportableType {
  final String? import;
  final String name;
  final bool isNullable;
  final List<ImportableType> typeArguments;

  String get identity => "$import#$name";

  const ImportableType({
    required this.name,
    this.import,
    this.isNullable = false,
    this.typeArguments = const [],
  });

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
          import == other.import &&
          name == other.name &&
          isNullable == other.isNullable &&
          ListEquality().equals(typeArguments, other.typeArguments));

  @override
  int get hashCode =>
      import.hashCode ^
      name.hashCode ^
      isNullable.hashCode ^
      ListEquality().hash(typeArguments);

  factory ImportableType.fromJson(Map<String, dynamic> json) {
    List<ImportableType> typeArguments = [];
    if (json['typeArguments'] != null) {
      json['typeArguments'].forEach((v) {
        typeArguments.add(ImportableType.fromJson(v));
      });
    }
    return ImportableType(
      import: json['import'],
      name: json['name'],
      isNullable: json['isNullable'],
      typeArguments: typeArguments,
    );
  }

  Map<String, dynamic> toJson() {
    // ignore: unnecessary_cast
    return {
      'import': this.import,
      'name': this.name,
      'isNullable': this.isNullable,
      if (typeArguments.isNotEmpty)
        "typeArguments": typeArguments.map((v) => v.toJson()).toList(),
    } as Map<String, dynamic>;
  }
}
