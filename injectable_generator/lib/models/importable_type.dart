import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

class ImportableType {
  final String import;
  final String name;
  final bool isNullable;
  final List<ImportableType> typeArguments;

  String get identity => "$import#$name";

  bool get isParametrized => typeArguments?.isNotEmpty == true;

  const ImportableType({
    this.import,
    @required this.name,
    this.isNullable = false,
    this.typeArguments,
  });

  ImportableType copyWith({
    String import,
    String name,
    bool isNullable,
    List<ImportableType> typeArguments,
  }) {
    if ((import == null || identical(import, this.import)) &&
        (name == null || identical(name, this.name)) &&
        (isNullable == null || identical(isNullable, this.isNullable)) &&
        (typeArguments == null ||
            identical(typeArguments, this.typeArguments))) {
      return this;
    }

    return ImportableType(
      import: import ?? this.import,
      name: name ?? this.name,
      isNullable: isNullable ?? this.isNullable,
      typeArguments: typeArguments ?? this.typeArguments,
    );
  }

  @override
  String toString() {
    if (isParametrized) {
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
    List<ImportableType> typeArguments;
    if (json['typeArguments'] != null) {
      typeArguments = [];
      json['typeArguments'].forEach((v) {
        typeArguments.add(ImportableType.fromJson(v));
      });
    }
    return ImportableType(
      import: json['import'] as String,
      name: json['name'] as String,
      isNullable: json['isNullable'] as bool,
      typeArguments: typeArguments,
    );
  }

  Map<String, dynamic> toJson() {
    // ignore: unnecessary_cast
    return {
      'import': this.import,
      'name': this.name,
      'isNullable': this.isNullable,
      if (isParametrized)
        "typeArguments": typeArguments.map((v) => v.toJson()).toList(),
    } as Map<String, dynamic>;
  }
}
