import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('ModuleConfig', () {
    late ImportableType type;

    setUp(() {
      type = const ImportableType(name: 'TestModule', import: 'test.dart');
    });

    test('should create ModuleConfig with required parameters', () {
      final config = ModuleConfig(
        isAbstract: true,
        isMethod: false,
        type: type,
        initializerName: 'init',
      );

      expect(config.isAbstract, isTrue);
      expect(config.isMethod, isFalse);
      expect(config.type, equals(type));
      expect(config.initializerName, equals('init'));
    });

    test('should create concrete module config', () {
      final config = ModuleConfig(
        isAbstract: false,
        isMethod: true,
        type: type,
        initializerName: 'configure',
      );

      expect(config.isAbstract, isFalse);
      expect(config.isMethod, isTrue);
    });

    group('copyWith', () {
      test('should copy with updated isAbstract', () {
        final original = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final copy = original.copyWith(isAbstract: false);

        expect(copy.isAbstract, isFalse);
        expect(copy.isMethod, equals(original.isMethod));
        expect(copy.type, equals(original.type));
        expect(copy.initializerName, equals(original.initializerName));
      });

      test('should copy with updated isModuleMethod', () {
        final original = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final copy = original.copyWith(isModuleMethod: true);

        expect(copy.isMethod, isTrue);
        expect(copy.isAbstract, equals(original.isAbstract));
      });

      test('should copy with updated module type', () {
        final original = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final newType = const ImportableType(name: 'NewModule', import: 'new.dart');
        final copy = original.copyWith(module: newType);

        expect(copy.type, equals(newType));
        expect(copy.isAbstract, equals(original.isAbstract));
      });

      test('should copy with updated initializerName', () {
        final original = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final copy = original.copyWith(initializerName: 'configure');

        expect(copy.initializerName, equals('configure'));
      });

      test('should return same instance when no changes', () {
        final original = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final copy = original.copyWith();

        expect(identical(copy, original), isTrue);
      });

      test('should copy with multiple fields updated', () {
        final original = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final copy = original.copyWith(
          isAbstract: false,
          isModuleMethod: true,
          initializerName: 'setup',
        );

        expect(copy.isAbstract, isFalse);
        expect(copy.isMethod, isTrue);
        expect(copy.initializerName, equals('setup'));
        expect(copy.type, equals(original.type));
      });
    });

    group('equality', () {
      test('should be equal when type is the same', () {
        final config1 = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final config2 = ModuleConfig(
          isAbstract: false,
          isMethod: true,
          type: type,
          initializerName: 'configure',
        );

        expect(config1, equals(config2));
      });

      test('should not be equal when type is different', () {
        final config1 = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final config2 = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: const ImportableType(name: 'OtherModule', import: 'other.dart'),
          initializerName: 'init',
        );

        expect(config1, isNot(equals(config2)));
      });

      test('should be identical to itself', () {
        final config = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        expect(config, equals(config));
      });
    });

    group('hashCode', () {
      test('should be same for equal configs', () {
        final config1 = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final config2 = ModuleConfig(
          isAbstract: false,
          isMethod: true,
          type: type,
          initializerName: 'configure',
        );

        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should be different for different types', () {
        final config1 = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final config2 = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: const ImportableType(name: 'OtherModule', import: 'other.dart'),
          initializerName: 'init',
        );

        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        final config = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final json = config.toJson();

        expect(json['isAbstract'], isTrue);
        expect(json['isMethod'], isFalse);
        expect(json['type'], isNotNull);
        expect(json['initializerName'], equals('init'));
      });

      test('should deserialize from JSON', () {
        final json = {
          'isAbstract': true,
          'isMethod': false,
          'type': {
            'name': 'TestModule',
            'import': 'test.dart',
            'isNullable': false,
            'isRecordType': false,
            'nameInRecord': null,
          },
          'initializerName': 'init',
        };

        final config = ModuleConfig.fromJson(json);

        expect(config.isAbstract, isTrue);
        expect(config.isMethod, isFalse);
        expect(config.type.name, equals('TestModule'));
        expect(config.type.import, equals('test.dart'));
        expect(config.initializerName, equals('init'));
      });

      test('should round-trip through JSON', () {
        final original = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final json = original.toJson();
        final deserialized = ModuleConfig.fromJson(json);

        expect(deserialized.isAbstract, equals(original.isAbstract));
        expect(deserialized.isMethod, equals(original.isMethod));
        expect(deserialized.type, equals(original.type));
        expect(deserialized.initializerName, equals(original.initializerName));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final config = ModuleConfig(
          isAbstract: true,
          isMethod: false,
          type: type,
          initializerName: 'init',
        );

        final str = config.toString();

        expect(str, contains('ModuleConfig'));
        expect(str, contains('isAbstract: true'));
        expect(str, contains('isModuleMethod: false'));
        expect(str, contains('initializerName: init'));
      });
    });
  });
}
