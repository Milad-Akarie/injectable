import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:test/test.dart';

void main() {
  group('DisposeFunctionConfig', () {
    test('should create DisposeFunctionConfig with required name', () {
      const config = DisposeFunctionConfig(name: 'dispose');

      expect(config.name, equals('dispose'));
      expect(config.isInstance, isFalse);
      expect(config.importableType, isNull);
    });

    test('should create instance dispose function', () {
      const config = DisposeFunctionConfig(
        name: 'cleanup',
        isInstance: true,
      );

      expect(config.isInstance, isTrue);
      expect(config.name, equals('cleanup'));
    });

    test('should create dispose function with importable type', () {
      const type = ImportableType(
        name: 'DisposeHandler',
        import: 'package:test/dispose.dart',
      );
      const config = DisposeFunctionConfig(
        name: 'dispose',
        importableType: type,
      );

      expect(config.importableType, equals(type));
      expect(config.name, equals('dispose'));
    });

    test('should create static dispose function', () {
      const type = ImportableType(name: 'ResourceManager');
      const config = DisposeFunctionConfig(
        name: 'cleanup',
        isInstance: false,
        importableType: type,
      );

      expect(config.isInstance, isFalse);
      expect(config.importableType, isNotNull);
    });

    group('copyWith', () {
      test('should copy with updated isInstance', () {
        const original = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: false,
        );

        final copy = original.copyWith(isInstance: true);

        expect(copy.isInstance, isTrue);
        expect(copy.name, equals(original.name));
        expect(copy.importableType, equals(original.importableType));
      });

      test('should copy with updated name', () {
        const original = DisposeFunctionConfig(name: 'dispose');

        final copy = original.copyWith(name: 'cleanup');

        expect(copy.name, equals('cleanup'));
        expect(copy.isInstance, equals(original.isInstance));
      });

      test('should copy with updated importableType', () {
        const original = DisposeFunctionConfig(name: 'dispose');
        const newType = ImportableType(name: 'NewHandler');

        final copy = original.copyWith(importableType: newType);

        expect(copy.importableType, equals(newType));
        expect(copy.name, equals(original.name));
      });

      test('should return same instance when no changes', () {
        const original = DisposeFunctionConfig(name: 'dispose');

        final copy = original.copyWith();

        expect(identical(copy, original), isTrue);
      });

      test('should copy with multiple fields updated', () {
        const original = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: false,
        );
        const newType = ImportableType(name: 'Handler');

        final copy = original.copyWith(
          name: 'cleanup',
          isInstance: true,
          importableType: newType,
        );

        expect(copy.name, equals('cleanup'));
        expect(copy.isInstance, isTrue);
        expect(copy.importableType, equals(newType));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const config1 = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: true,
        );
        const config2 = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: true,
        );

        expect(config1, equals(config2));
      });

      test('should not be equal when name differs', () {
        const config1 = DisposeFunctionConfig(name: 'dispose');
        const config2 = DisposeFunctionConfig(name: 'cleanup');

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when isInstance differs', () {
        const config1 = DisposeFunctionConfig(name: 'dispose', isInstance: true);
        const config2 = DisposeFunctionConfig(name: 'dispose', isInstance: false);

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when importableType differs', () {
        const type1 = ImportableType(name: 'Handler1');
        const type2 = ImportableType(name: 'Handler2');
        const config1 = DisposeFunctionConfig(name: 'dispose', importableType: type1);
        const config2 = DisposeFunctionConfig(name: 'dispose', importableType: type2);

        expect(config1, isNot(equals(config2)));
      });

      test('should be identical to itself', () {
        const config = DisposeFunctionConfig(name: 'dispose');

        expect(config, equals(config));
      });

      test('should be equal with same importableType', () {
        const type = ImportableType(name: 'Handler');
        const config1 = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: true,
          importableType: type,
        );
        const config2 = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: true,
          importableType: type,
        );

        expect(config1, equals(config2));
      });
    });

    group('hashCode', () {
      test('should be same for equal configs', () {
        const config1 = DisposeFunctionConfig(name: 'dispose', isInstance: true);
        const config2 = DisposeFunctionConfig(name: 'dispose', isInstance: true);

        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should be different when name differs', () {
        const config1 = DisposeFunctionConfig(name: 'dispose');
        const config2 = DisposeFunctionConfig(name: 'cleanup');

        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });

      test('should be different when isInstance differs', () {
        const config1 = DisposeFunctionConfig(name: 'dispose', isInstance: true);
        const config2 = DisposeFunctionConfig(name: 'dispose', isInstance: false);

        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON without importableType', () {
        const config = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: true,
        );

        final json = config.toJson();

        expect(json['name'], equals('dispose'));
        expect(json['isInstance'], isTrue);
        expect(json.containsKey('importableType'), isFalse);
      });

      test('should serialize to JSON with importableType', () {
        const type = ImportableType(
          name: 'DisposeHandler',
          import: 'package:test/dispose.dart',
        );
        const config = DisposeFunctionConfig(
          name: 'cleanup',
          isInstance: false,
          importableType: type,
        );

        final json = config.toJson();

        expect(json['name'], equals('cleanup'));
        expect(json['isInstance'], isFalse);
        expect(json['importableType'], isNotNull);
        expect(json['importableType']['name'], equals('DisposeHandler'));
      });

      test('should deserialize from JSON without importableType', () {
        final json = {
          'name': 'dispose',
          'isInstance': true,
        };

        final config = DisposeFunctionConfig.fromJson(json);

        expect(config.name, equals('dispose'));
        expect(config.isInstance, isTrue);
        expect(config.importableType, isNull);
      });

      test('should deserialize from JSON with importableType', () {
        final json = {
          'name': 'cleanup',
          'isInstance': false,
          'importableType': {
            'name': 'DisposeHandler',
            'import': 'package:test/dispose.dart',
            'isNullable': false,
            'isRecordType': false,
            'nameInRecord': null,
          },
        };

        final config = DisposeFunctionConfig.fromJson(json);

        expect(config.name, equals('cleanup'));
        expect(config.isInstance, isFalse);
        expect(config.importableType, isNotNull);
        expect(config.importableType!.name, equals('DisposeHandler'));
        expect(config.importableType!.import, equals('package:test/dispose.dart'));
      });

      test('should round-trip through JSON', () {
        const original = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: true,
        );

        final json = original.toJson();
        final deserialized = DisposeFunctionConfig.fromJson(json);

        expect(deserialized, equals(original));
      });

      test('should round-trip through JSON with importableType', () {
        const type = ImportableType(
          name: 'Handler',
          import: 'package:test/handler.dart',
        );
        const original = DisposeFunctionConfig(
          name: 'cleanup',
          isInstance: false,
          importableType: type,
        );

        final json = original.toJson();
        final deserialized = DisposeFunctionConfig.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized.importableType, equals(type));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        const config = DisposeFunctionConfig(
          name: 'dispose',
          isInstance: true,
        );

        final str = config.toString();

        expect(str, contains('DisposeFunctionConfig'));
        expect(str, contains('isInstance: true'));
        expect(str, contains('name: dispose'));
      });

      test('should include importableType in string', () {
        const type = ImportableType(name: 'Handler');
        const config = DisposeFunctionConfig(
          name: 'cleanup',
          importableType: type,
        );

        final str = config.toString();

        expect(str, contains('importableType: Handler'));
      });

      test('should show null importableType', () {
        const config = DisposeFunctionConfig(name: 'dispose');

        final str = config.toString();

        expect(str, contains('importableType: null'));
      });
    });
  });
}
