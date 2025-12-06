import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:test/test.dart';

void main() {
  group('InjectedDependency', () {
    late ImportableType type;

    setUp(() {
      type = const ImportableType(name: 'String', import: 'dart:core');
    });

    test('should create InjectedDependency with required parameters', () {
      final dep = InjectedDependency(
        type: type,
        paramName: 'value',
      );

      expect(dep.type, equals(type));
      expect(dep.paramName, equals('value'));
      expect(dep.instanceName, isNull);
      expect(dep.isFactoryParam, isFalse);
      expect(dep.isPositional, isTrue);
      expect(dep.isRequired, isTrue);
    });

    test('should create factory param dependency', () {
      final dep = InjectedDependency(
        type: type,
        paramName: 'input',
        isFactoryParam: true,
      );

      expect(dep.isFactoryParam, isTrue);
    });

    test('should create named dependency', () {
      final dep = InjectedDependency(
        type: type,
        paramName: 'config',
        isPositional: false,
      );

      expect(dep.isPositional, isFalse);
    });

    test('should create optional dependency', () {
      final dep = InjectedDependency(
        type: type,
        paramName: 'optional',
        isRequired: false,
      );

      expect(dep.isRequired, isFalse);
    });

    test('should create dependency with instance name', () {
      final dep = InjectedDependency(
        type: type,
        paramName: 'service',
        instanceName: 'primary',
      );

      expect(dep.instanceName, equals('primary'));
    });

    test('should create complex dependency with all parameters', () {
      final dep = InjectedDependency(
        type: type,
        paramName: 'param',
        instanceName: 'test',
        isFactoryParam: true,
        isPositional: false,
        isRequired: false,
      );

      expect(dep.type, equals(type));
      expect(dep.paramName, equals('param'));
      expect(dep.instanceName, equals('test'));
      expect(dep.isFactoryParam, isTrue);
      expect(dep.isPositional, isFalse);
      expect(dep.isRequired, isFalse);
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final dep1 = InjectedDependency(
          type: type,
          paramName: 'value',
          instanceName: 'main',
          isFactoryParam: true,
          isPositional: false,
          isRequired: false,
        );

        final dep2 = InjectedDependency(
          type: type,
          paramName: 'value',
          instanceName: 'main',
          isFactoryParam: true,
          isPositional: false,
          isRequired: false,
        );

        expect(dep1, equals(dep2));
      });

      test('should not be equal when type differs', () {
        final dep1 = InjectedDependency(type: type, paramName: 'value');
        final dep2 = InjectedDependency(
          type: const ImportableType(name: 'int'),
          paramName: 'value',
        );

        expect(dep1, isNot(equals(dep2)));
      });

      test('should not be equal when paramName differs', () {
        final dep1 = InjectedDependency(type: type, paramName: 'value1');
        final dep2 = InjectedDependency(type: type, paramName: 'value2');

        expect(dep1, isNot(equals(dep2)));
      });

      test('should not be equal when instanceName differs', () {
        final dep1 = InjectedDependency(
          type: type,
          paramName: 'value',
          instanceName: 'main',
        );
        final dep2 = InjectedDependency(
          type: type,
          paramName: 'value',
          instanceName: 'secondary',
        );

        expect(dep1, isNot(equals(dep2)));
      });

      test('should not be equal when isFactoryParam differs', () {
        final dep1 = InjectedDependency(
          type: type,
          paramName: 'value',
          isFactoryParam: true,
        );
        final dep2 = InjectedDependency(
          type: type,
          paramName: 'value',
          isFactoryParam: false,
        );

        expect(dep1, isNot(equals(dep2)));
      });

      test('should not be equal when isPositional differs', () {
        final dep1 = InjectedDependency(
          type: type,
          paramName: 'value',
          isPositional: true,
        );
        final dep2 = InjectedDependency(
          type: type,
          paramName: 'value',
          isPositional: false,
        );

        expect(dep1, isNot(equals(dep2)));
      });

      test('should not be equal when isRequired differs', () {
        final dep1 = InjectedDependency(
          type: type,
          paramName: 'value',
          isRequired: true,
        );
        final dep2 = InjectedDependency(
          type: type,
          paramName: 'value',
          isRequired: false,
        );

        expect(dep1, isNot(equals(dep2)));
      });

      test('should be identical to itself', () {
        final dep = InjectedDependency(type: type, paramName: 'value');

        expect(dep, equals(dep));
      });
    });

    group('hashCode', () {
      test('should be same for equal dependencies', () {
        final dep1 = InjectedDependency(
          type: type,
          paramName: 'value',
          isFactoryParam: true,
        );
        final dep2 = InjectedDependency(
          type: type,
          paramName: 'value',
          isFactoryParam: true,
        );

        expect(dep1.hashCode, equals(dep2.hashCode));
      });

      test('should be different when type differs', () {
        final dep1 = InjectedDependency(type: type, paramName: 'value');
        final dep2 = InjectedDependency(
          type: const ImportableType(name: 'int'),
          paramName: 'value',
        );

        expect(dep1.hashCode, isNot(equals(dep2.hashCode)));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final dep = InjectedDependency(
          type: type,
          paramName: 'value',
          instanceName: 'main',
          isFactoryParam: true,
          isPositional: false,
          isRequired: false,
        );

        final str = dep.toString();

        expect(str, contains('InjectedDependency'));
        expect(str, contains('type: String'));
        expect(str, contains('paramName: value'));
        expect(str, contains('instanceName: main'));
        expect(str, contains('isFactoryParam: true'));
        expect(str, contains('isPositional: false'));
        expect(str, contains('isRequired: false'));
      });

      test('should handle null instanceName in toString', () {
        final dep = InjectedDependency(type: type, paramName: 'value');

        final str = dep.toString();

        expect(str, contains('instanceName: null'));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        final dep = InjectedDependency(
          type: type,
          paramName: 'value',
          instanceName: 'main',
          isFactoryParam: true,
          isPositional: false,
          isRequired: false,
        );

        final json = dep.toJson();

        expect(json['paramName'], equals('value'));
        expect(json['instanceName'], equals('main'));
        expect(json['isFactoryParam'], isTrue);
        expect(json['isPositional'], isFalse);
        expect(json['isRequired'], isFalse);
        expect(json['type'], isNotNull);
      });

      test('should serialize null instanceName', () {
        final dep = InjectedDependency(type: type, paramName: 'value');

        final json = dep.toJson();

        expect(json['instanceName'], isNull);
      });

      test('should deserialize from JSON', () {
        final json = {
          'type': {
            'name': 'String',
            'import': 'dart:core',
            'isNullable': false,
            'isRecordType': false,
            'nameInRecord': null,
          },
          'paramName': 'value',
          'instanceName': 'main',
          'isFactoryParam': true,
          'isPositional': false,
          'isRequired': false,
        };

        final dep = InjectedDependency.fromJson(json);

        expect(dep.type.name, equals('String'));
        expect(dep.paramName, equals('value'));
        expect(dep.instanceName, equals('main'));
        expect(dep.isFactoryParam, isTrue);
        expect(dep.isPositional, isFalse);
        expect(dep.isRequired, isFalse);
      });

      test('should deserialize with null instanceName', () {
        final json = {
          'type': {
            'name': 'String',
            'import': 'dart:core',
            'isNullable': false,
            'isRecordType': false,
            'nameInRecord': null,
          },
          'paramName': 'value',
          'instanceName': null,
          'isFactoryParam': false,
          'isPositional': true,
          'isRequired': true,
        };

        final dep = InjectedDependency.fromJson(json);

        expect(dep.instanceName, isNull);
      });

      test(
        'should deserialize with missing isRequired (backwards compatibility)',
        () {
          final json = {
            'type': {
              'name': 'String',
              'import': 'dart:core',
              'isNullable': false,
              'isRecordType': false,
              'nameInRecord': null,
            },
            'paramName': 'value',
            'instanceName': null,
            'isFactoryParam': false,
            'isPositional': true,
          };

          final dep = InjectedDependency.fromJson(json);

          expect(dep.isRequired, isFalse); // defaults to false when missing
        },
      );

      test('should round-trip through JSON', () {
        final original = InjectedDependency(
          type: type,
          paramName: 'value',
          instanceName: 'test',
          isFactoryParam: true,
          isPositional: false,
          isRequired: false,
        );

        final json = original.toJson();
        final deserialized = InjectedDependency.fromJson(json);

        expect(deserialized, equals(original));
      });

      test('should round-trip through JSON with defaults', () {
        final original = InjectedDependency(
          type: type,
          paramName: 'value',
        );

        final json = original.toJson();
        final deserialized = InjectedDependency.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('different dependency types', () {
      test('should support positional required dependency', () {
        final dep = InjectedDependency(
          type: type,
          paramName: 'required',
          isPositional: true,
          isRequired: true,
        );

        expect(dep.isPositional, isTrue);
        expect(dep.isRequired, isTrue);
      });

      test('should support named optional dependency', () {
        final dep = InjectedDependency(
          type: type,
          paramName: 'optional',
          isPositional: false,
          isRequired: false,
        );

        expect(dep.isPositional, isFalse);
        expect(dep.isRequired, isFalse);
      });

      test('should support factory param with instance name', () {
        final dep = InjectedDependency(
          type: type,
          paramName: 'factory',
          isFactoryParam: true,
          instanceName: 'custom',
        );

        expect(dep.isFactoryParam, isTrue);
        expect(dep.instanceName, equals('custom'));
      });
    });

    group('with different types', () {
      test('should work with nullable type', () {
        const nullableType = ImportableType(
          name: 'String',
          isNullable: true,
        );
        final dep = InjectedDependency(
          type: nullableType,
          paramName: 'nullable',
        );

        expect(dep.type.isNullable, isTrue);
      });

      test('should work with generic type', () {
        const genericType = ImportableType(
          name: 'List',
          typeArguments: [ImportableType(name: 'String')],
        );
        final dep = InjectedDependency(
          type: genericType,
          paramName: 'list',
        );

        expect(dep.type.typeArguments.length, equals(1));
      });

      test('should work with record type', () {
        const recordType = ImportableType.record(
          name: 'MyRecord',
          nameInRecord: 'field',
        );
        final dep = InjectedDependency(
          type: recordType,
          paramName: 'record',
        );

        expect(dep.type.isRecordType, isTrue);
      });
    });
  });
}
