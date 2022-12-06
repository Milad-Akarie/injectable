import 'package:collection/collection.dart';

class ImportableType {
  final String? import;
  final String name;
  final bool isNullable;
  final List<ImportableType> typeArguments;
  final Set<String>? otherImports;

  String get identity => "$import#$name";

  const ImportableType({
    required this.name,
    this.import,
    this.isNullable = false,
    this.typeArguments = const [],
    this.otherImports,
  });

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
          ListEquality().equals(typeArguments, other.typeArguments));

  @override
  int get hashCode =>
      SetEquality().hash(allImports) ^
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
      otherImports:
          (json['otherImports'] as List<dynamic>?)?.toSet().cast<String>(),
      typeArguments: typeArguments,
    );
  }

  Map<String, dynamic> toJson() {
    // ignore: unnecessary_cast
    return {
      'import': import,
      'name': name,
      'isNullable': isNullable,
      if (typeArguments.isNotEmpty)
        "typeArguments": typeArguments.map((v) => v.toJson()).toList(),
      if (otherImports?.isNotEmpty == true)
        "otherImports": otherImports?.toList(),
    } as Map<String, dynamic>;
  }
}
