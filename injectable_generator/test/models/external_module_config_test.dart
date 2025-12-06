import 'package:injectable_generator/models/external_module_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:test/test.dart';

void main() {
  group('ExternalModuleConfig', () {
    late ImportableType module;

    setUp(() {
      module = const ImportableType(
        name: 'ExternalModule',
        import: 'package:external/module.dart',
      );
    });

    test('should create ExternalModuleConfig with module only', () {
      final config = ExternalModuleConfig(module);

      expect(config.module, equals(module));
      expect(config.scope, isNull);
    });

    test('should create ExternalModuleConfig with module and scope', () {
      final config = ExternalModuleConfig(module, 'production');

      expect(config.module, equals(module));
      expect(config.scope, equals('production'));
    });

    test('should create config with null scope explicitly', () {
      final config = ExternalModuleConfig(module, null);

      expect(config.module, equals(module));
      expect(config.scope, isNull);
    });

    group('equality', () {
      test('should be equal when module and scope match', () {
        final config1 = ExternalModuleConfig(module, 'test');
        final config2 = ExternalModuleConfig(module, 'test');

        expect(config1, equals(config2));
      });

      test('should not be equal when modules differ', () {
        const module2 = ImportableType(
          name: 'OtherModule',
          import: 'package:other/module.dart',
        );
        final config1 = ExternalModuleConfig(module);
        final config2 = ExternalModuleConfig(module2);

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when scopes differ', () {
        final config1 = ExternalModuleConfig(module, 'dev');
        final config2 = ExternalModuleConfig(module, 'prod');

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when one has scope and other does not', () {
        final config1 = ExternalModuleConfig(module);
        final config2 = ExternalModuleConfig(module, 'test');

        expect(config1, isNot(equals(config2)));
      });

      test('should be equal when both have null scope', () {
        final config1 = ExternalModuleConfig(module);
        final config2 = ExternalModuleConfig(module, null);

        expect(config1, equals(config2));
      });

      test('should be identical to itself', () {
        final config = ExternalModuleConfig(module, 'test');

        expect(config, equals(config));
      });

      test('should not equal different type', () {
        final config = ExternalModuleConfig(module);

        expect(config, isNot(equals('not a config')));
      });

      test('should not equal object with different runtimeType', () {
        final config = ExternalModuleConfig(module);
        final other = Object();

        expect(config, isNot(equals(other)));
      });
    });

    group('hashCode', () {
      test('should be same for equal configs', () {
        final config1 = ExternalModuleConfig(module, 'test');
        final config2 = ExternalModuleConfig(module, 'test');

        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should be different when modules differ', () {
        const module2 = ImportableType(
          name: 'OtherModule',
          import: 'package:other/module.dart',
        );
        final config1 = ExternalModuleConfig(module);
        final config2 = ExternalModuleConfig(module2);

        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });

      test('should be different when scopes differ', () {
        final config1 = ExternalModuleConfig(module, 'dev');
        final config2 = ExternalModuleConfig(module, 'prod');

        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });

      test('should be same when both have null scope', () {
        final config1 = ExternalModuleConfig(module);
        final config2 = ExternalModuleConfig(module, null);

        expect(config1.hashCode, equals(config2.hashCode));
      });
    });

    group('different scopes', () {
      test('should support empty string scope', () {
        final config = ExternalModuleConfig(module, '');

        expect(config.scope, equals(''));
      });

      test('should differentiate empty string from null scope', () {
        final config1 = ExternalModuleConfig(module, '');
        final config2 = ExternalModuleConfig(module, null);

        expect(config1, isNot(equals(config2)));
      });

      test('should support various scope names', () {
        final scopes = ['dev', 'test', 'prod', 'staging', 'local'];

        for (final scope in scopes) {
          final config = ExternalModuleConfig(module, scope);
          expect(config.scope, equals(scope));
        }
      });
    });

    group('different module types', () {
      test('should support module without import', () {
        const localModule = ImportableType(name: 'LocalModule');
        final config = ExternalModuleConfig(localModule);

        expect(config.module.name, equals('LocalModule'));
        expect(config.module.import, isNull);
      });

      test('should support module with type arguments', () {
        const typeArg = ImportableType(name: 'String');
        const genericModule = ImportableType(
          name: 'GenericModule',
          typeArguments: [typeArg],
        );
        final config = ExternalModuleConfig(genericModule);

        expect(config.module.typeArguments.length, equals(1));
      });

      test('should support nullable module type', () {
        const nullableModule = ImportableType(
          name: 'NullableModule',
          isNullable: true,
        );
        final config = ExternalModuleConfig(nullableModule);

        expect(config.module.isNullable, isTrue);
      });
    });

    group('use cases', () {
      test('should represent global external module', () {
        const globalModule = ImportableType(
          name: 'GlobalServiceModule',
          import: 'package:services/global_module.dart',
        );
        final config = ExternalModuleConfig(globalModule);

        expect(config.module.name, equals('GlobalServiceModule'));
        expect(config.scope, isNull);
      });

      test('should represent scoped external module', () {
        const scopedModule = ImportableType(
          name: 'AuthModule',
          import: 'package:auth/module.dart',
        );
        final config = ExternalModuleConfig(scopedModule, 'authenticated');

        expect(config.module.name, equals('AuthModule'));
        expect(config.scope, equals('authenticated'));
      });

      test('should represent test-specific module', () {
        const testModule = ImportableType(
          name: 'MockModule',
          import: 'package:test/mocks.dart',
        );
        final config = ExternalModuleConfig(testModule, 'test');

        expect(config.module.name, equals('MockModule'));
        expect(config.scope, equals('test'));
      });
    });

    group('Set operations', () {
      test('should work correctly in a Set', () {
        final config1 = ExternalModuleConfig(module, 'test');
        final config2 = ExternalModuleConfig(module, 'test');
        final config3 = ExternalModuleConfig(module, 'prod');

        final set = {config1, config2, config3};

        expect(set.length, equals(2)); // config1 and config2 are equal
        expect(set.contains(config1), isTrue);
        expect(set.contains(config3), isTrue);
      });

      test('should distinguish different modules in Set', () {
        const module2 = ImportableType(name: 'Module2');
        final config1 = ExternalModuleConfig(module);
        final config2 = ExternalModuleConfig(module2);

        final set = {config1, config2};

        expect(set.length, equals(2));
      });
    });

    group('Map operations', () {
      test('should work correctly as Map key', () {
        final config1 = ExternalModuleConfig(module, 'test');
        final config2 = ExternalModuleConfig(module, 'test');

        final map = {config1: 'value1'};
        map[config2] = 'value2';

        expect(map.length, equals(1)); // config1 and config2 are equal
        expect(map[config1], equals('value2'));
      });

      test('should distinguish different configs as Map keys', () {
        final config1 = ExternalModuleConfig(module, 'test');
        final config2 = ExternalModuleConfig(module, 'prod');

        final map = {config1: 'value1', config2: 'value2'};

        expect(map.length, equals(2));
        expect(map[config1], equals('value1'));
        expect(map[config2], equals('value2'));
      });
    });
  });
}
