import 'package:injectable_generator/models/importable_type.dart';
import 'package:test/test.dart';

void main() {
  group('ImportableType', () {
    test('should create ImportableType with required name', () {
      const type = ImportableType(name: 'String');

      expect(type.name, equals('String'));
      expect(type.import, isNull);
      expect(type.isNullable, isFalse);
      expect(type.typeArguments, isEmpty);
      expect(type.isRecordType, isFalse);
    });

    test('should create ImportableType with import', () {
      const type = ImportableType(
        name: 'MyClass',
        import: 'package:my_package/my_class.dart',
      );

      expect(type.name, equals('MyClass'));
      expect(type.import, equals('package:my_package/my_class.dart'));
    });

    test('should create nullable ImportableType', () {
      const type = ImportableType(
        name: 'String',
        isNullable: true,
      );

      expect(type.isNullable, isTrue);
    });

    test('should create ImportableType with type arguments', () {
      const typeArg = ImportableType(name: 'String');
      const type = ImportableType(
        name: 'List',
        typeArguments: [typeArg],
      );

      expect(type.typeArguments.length, equals(1));
      expect(type.typeArguments.first.name, equals('String'));
    });

    test('should create record type', () {
      const type = ImportableType.record(
        name: 'MyRecord',
        import: 'test.dart',
      );

      expect(type.isRecordType, isTrue);
      expect(type.name, equals('MyRecord'));
    });

    test('should create record type with named field', () {
      const type = ImportableType.record(
        name: 'String',
        nameInRecord: 'userId',
      );

      expect(type.isRecordType, isTrue);
      expect(type.nameInRecord, equals('userId'));
      expect(type.isNamedRecordField, isTrue);
    });

    test('should not be named record field when nameInRecord is null', () {
      const type = ImportableType(name: 'String');

      expect(type.isNamedRecordField, isFalse);
    });

    group('allImports', () {
      test('should include primary import', () {
        const type = ImportableType(
          name: 'MyClass',
          import: 'package:my_package/my_class.dart',
        );

        expect(type.allImports, contains('package:my_package/my_class.dart'));
      });

      test('should include other imports', () {
        const type = ImportableType(
          name: 'MyClass',
          import: 'package:my_package/my_class.dart',
          otherImports: {'package:another/lib.dart'},
        );

        expect(type.allImports, contains('package:my_package/my_class.dart'));
        expect(type.allImports, contains('package:another/lib.dart'));
      });

      test('should handle null import', () {
        const type = ImportableType(name: 'String');

        expect(type.allImports, contains(null));
      });
    });

    group('identity', () {
      test('should combine import and name', () {
        const type = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
        );

        expect(type.identity, equals('package:test/test.dart#MyClass'));
      });

      test('should handle null import', () {
        const type = ImportableType(name: 'String');

        expect(type.identity, equals('null#String'));
      });
    });

    group('toString', () {
      test('should return name for simple type', () {
        const type = ImportableType(name: 'String');

        expect(type.toString(), equals('String'));
      });

      test('should include type arguments', () {
        const typeArg = ImportableType(name: 'int');
        const type = ImportableType(
          name: 'List',
          typeArguments: [typeArg],
        );

        expect(type.toString(), contains('List'));
        expect(type.toString(), contains('int'));
      });

      test('should include multiple type arguments', () {
        const keyType = ImportableType(name: 'String');
        const valueType = ImportableType(name: 'int');
        const type = ImportableType(
          name: 'Map',
          typeArguments: [keyType, valueType],
        );

        expect(type.toString(), contains('Map'));
        expect(type.toString(), contains('String'));
        expect(type.toString(), contains('int'));
      });
    });

    group('equality', () {
      test('should be equal when name and import match', () {
        const type1 = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
        );
        const type2 = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
        );

        expect(type1, equals(type2));
      });

      test('should not be equal when names differ', () {
        const type1 = ImportableType(name: 'ClassA');
        const type2 = ImportableType(name: 'ClassB');

        expect(type1, isNot(equals(type2)));
      });

      test('should not be equal when nullable differs', () {
        const type1 = ImportableType(name: 'String', isNullable: false);
        const type2 = ImportableType(name: 'String', isNullable: true);

        expect(type1, isNot(equals(type2)));
      });

      test('should not be equal when type arguments differ', () {
        const typeArg1 = ImportableType(name: 'String');
        const typeArg2 = ImportableType(name: 'int');
        const type1 = ImportableType(name: 'List', typeArguments: [typeArg1]);
        const type2 = ImportableType(name: 'List', typeArguments: [typeArg2]);

        expect(type1, isNot(equals(type2)));
      });

      test('should not be equal when record type differs', () {
        const type1 = ImportableType(name: 'MyType');
        const type2 = ImportableType.record(name: 'MyType');

        expect(type1, isNot(equals(type2)));
      });

      test('should not be equal when nameInRecord differs', () {
        const type1 = ImportableType.record(name: 'String', nameInRecord: 'id');
        const type2 = ImportableType.record(
          name: 'String',
          nameInRecord: 'name',
        );

        expect(type1, isNot(equals(type2)));
      });

      test('should be identical to itself', () {
        const type = ImportableType(name: 'String');

        expect(type, equals(type));
      });

      test('should be equal when imports intersect', () {
        const type1 = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
        );
        const type2 = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
          otherImports: {'package:other/other.dart'},
        );

        expect(type1, equals(type2));
      });
    });

    group('hashCode', () {
      test('should be same for equal types', () {
        const type1 = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
        );
        const type2 = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
        );

        expect(type1.hashCode, equals(type2.hashCode));
      });

      test('should be different for different types', () {
        const type1 = ImportableType(name: 'ClassA');
        const type2 = ImportableType(name: 'ClassB');

        expect(type1.hashCode, isNot(equals(type2.hashCode)));
      });
    });

    group('JSON serialization', () {
      test('should serialize simple type to JSON', () {
        const type = ImportableType(
          name: 'String',
          import: 'dart:core',
        );

        final json = type.toJson();

        expect(json['name'], equals('String'));
        expect(json['import'], equals('dart:core'));
        expect(json['isNullable'], isFalse);
        expect(json['isRecordType'], isFalse);
      });

      test('should serialize nullable type to JSON', () {
        const type = ImportableType(
          name: 'String',
          isNullable: true,
        );

        final json = type.toJson();

        expect(json['isNullable'], isTrue);
      });

      test('should serialize type with type arguments', () {
        const typeArg = ImportableType(name: 'int');
        const type = ImportableType(
          name: 'List',
          typeArguments: [typeArg],
        );

        final json = type.toJson();

        expect(json['typeArguments'], isNotNull);
        expect(json['typeArguments'], isList);
        expect(json['typeArguments'].length, equals(1));
      });

      test('should serialize record type', () {
        const type = ImportableType.record(
          name: 'MyRecord',
          nameInRecord: 'userId',
        );

        final json = type.toJson();

        expect(json['isRecordType'], isTrue);
        expect(json['nameInRecord'], equals('userId'));
      });

      test('should serialize type with other imports', () {
        const type = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
          otherImports: {'package:other1/lib.dart', 'package:other2/lib.dart'},
        );

        final json = type.toJson();

        expect(json['otherImports'], isNotNull);
        expect(json['otherImports'], isList);
        expect(json['otherImports'].length, equals(2));
      });

      test('should not include empty typeArguments in JSON', () {
        const type = ImportableType(name: 'String');

        final json = type.toJson();

        expect(json.containsKey('typeArguments'), isFalse);
      });

      test('should not include empty otherImports in JSON', () {
        const type = ImportableType(name: 'String');

        final json = type.toJson();

        expect(json.containsKey('otherImports'), isFalse);
      });

      test('should deserialize from JSON', () {
        final json = {
          'name': 'String',
          'import': 'dart:core',
          'isNullable': true,
          'isRecordType': false,
          'nameInRecord': null,
        };

        final type = ImportableType.fromJson(json);

        expect(type.name, equals('String'));
        expect(type.import, equals('dart:core'));
        expect(type.isNullable, isTrue);
        expect(type.isRecordType, isFalse);
      });

      test('should deserialize with type arguments', () {
        final json = {
          'name': 'List',
          'import': 'dart:core',
          'isNullable': false,
          'isRecordType': false,
          'nameInRecord': null,
          'typeArguments': [
            {
              'name': 'int',
              'import': 'dart:core',
              'isNullable': false,
              'isRecordType': false,
              'nameInRecord': null,
            },
          ],
        };

        final type = ImportableType.fromJson(json);

        expect(type.typeArguments.length, equals(1));
        expect(type.typeArguments.first.name, equals('int'));
      });

      test('should deserialize with other imports', () {
        final json = {
          'name': 'MyClass',
          'import': 'package:test/test.dart',
          'isNullable': false,
          'isRecordType': false,
          'nameInRecord': null,
          'otherImports': ['package:other/lib.dart'],
        };

        final type = ImportableType.fromJson(json);

        expect(type.otherImports, isNotNull);
        expect(type.otherImports!.length, equals(1));
        expect(type.otherImports, contains('package:other/lib.dart'));
      });

      test('should round-trip through JSON', () {
        const original = ImportableType(
          name: 'MyClass',
          import: 'package:test/test.dart',
          isNullable: true,
          typeArguments: [ImportableType(name: 'String')],
          otherImports: {'package:other/lib.dart'},
        );

        final json = original.toJson();
        final deserialized = ImportableType.fromJson(json);

        expect(deserialized, equals(original));
      });

      test('should round-trip record type through JSON', () {
        const original = ImportableType.record(
          name: 'MyRecord',
          import: 'test.dart',
          nameInRecord: 'userId',
        );

        final json = original.toJson();
        final deserialized = ImportableType.fromJson(json);

        expect(deserialized, equals(original));
      });
    });
  });
}
