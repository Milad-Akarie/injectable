import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyConfig', () {
    const type = ImportableType(name: 'IService', import: 'test.dart');
    const typeImpl = ImportableType(name: 'ServiceImpl', import: 'test.dart');

    test('should create minimal DependencyConfig', () {
      final config = DependencyConfig(
        type: type,
        typeImpl: typeImpl,
      );

      expect(config.type, equals(type));
      expect(config.typeImpl, equals(typeImpl));
      expect(config.injectableType, equals(InjectableType.factory));
      expect(config.dependencies, isEmpty);
      expect(config.instanceName, isNull);
      expect(config.environments, isEmpty);
      expect(config.isAsync, isFalse);
      expect(config.canBeConst, isFalse);
      expect(config.cache, isFalse);
    });

    test('should create factory config with factory helper', () {
      final config = DependencyConfig.factory('Service');

      expect(config.type.name, equals('Service'));
      expect(config.typeImpl.name, equals('Service'));
      expect(config.injectableType, equals(InjectableType.factory));
    });

    test('should create factory with different implementation', () {
      final config = DependencyConfig.factory('IService', typeImpl: 'ServiceImpl');

      expect(config.type.name, equals('IService'));
      expect(config.typeImpl.name, equals('ServiceImpl'));
    });

    test('should create factory with dependencies', () {
      final config = DependencyConfig.factory('Service', deps: ['Dependency1', 'Dependency2']);

      expect(config.dependencies.length, equals(2));
      expect(config.dependencies[0].type.name, equals('Dependency1'));
      expect(config.dependencies[1].type.name, equals('Dependency2'));
    });

    test('should create factory with environments', () {
      final config = DependencyConfig.factory('Service', envs: ['dev', 'test']);

      expect(config.environments, equals(['dev', 'test']));
    });

    test('should create factory with order', () {
      final config = DependencyConfig.factory('Service', order: 5);

      expect(config.orderPosition, equals(5));
    });

    test('should create factory with cache', () {
      final config = DependencyConfig.factory('Service', cache: true);

      expect(config.cache, isTrue);
    });

    test('should create singleton config with helper', () {
      final config = DependencyConfig.singleton('Service');

      expect(config.injectableType, equals(InjectableType.singleton));
      expect(config.type.name, equals('Service'));
    });

    test('should create lazy singleton', () {
      final config = DependencyConfig.singleton('Service', lazy: true);

      expect(config.injectableType, equals(InjectableType.lazySingleton));
    });

    test('should create singleton with dependencies', () {
      final config = DependencyConfig.singleton('Service', deps: ['Dep1']);

      expect(config.dependencies.length, equals(1));
      expect(config.dependencies[0].type.name, equals('Dep1'));
    });

    group('isFromModule', () {
      test('should return true when moduleConfig is set', () {
        final config = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          moduleConfig: const ModuleConfig(
            isAbstract: true,
            isMethod: false,
            type: ImportableType(name: 'Module'),
            initializerName: 'init',
          ),
        );

        expect(config.isFromModule, isTrue);
      });

      test('should return false when moduleConfig is null', () {
        final config = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
        );

        expect(config.isFromModule, isFalse);
      });
    });

    group('positionalDependencies', () {
      test('should return only positional dependencies', () {
        final config = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          dependencies: [
            InjectedDependency(
              type: const ImportableType(name: 'Dep1'),
              paramName: 'dep1',
              isPositional: true,
            ),
            InjectedDependency(
              type: const ImportableType(name: 'Dep2'),
              paramName: 'dep2',
              isPositional: false,
            ),
            InjectedDependency(
              type: const ImportableType(name: 'Dep3'),
              paramName: 'dep3',
              isPositional: true,
            ),
          ],
        );

        final positional = config.positionalDependencies;

        expect(positional.length, equals(2));
        expect(positional[0].paramName, equals('dep1'));
        expect(positional[1].paramName, equals('dep3'));
      });

      test('should return empty list when no positional dependencies', () {
        final config = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          dependencies: [
            InjectedDependency(
              type: const ImportableType(name: 'Dep1'),
              paramName: 'dep1',
              isPositional: false,
            ),
          ],
        );

        expect(config.positionalDependencies, isEmpty);
      });
    });

    group('namedDependencies', () {
      test('should return only named dependencies', () {
        final config = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          dependencies: [
            InjectedDependency(
              type: const ImportableType(name: 'Dep1'),
              paramName: 'dep1',
              isPositional: true,
            ),
            InjectedDependency(
              type: const ImportableType(name: 'Dep2'),
              paramName: 'dep2',
              isPositional: false,
            ),
            InjectedDependency(
              type: const ImportableType(name: 'Dep3'),
              paramName: 'dep3',
              isPositional: false,
            ),
          ],
        );

        final named = config.namedDependencies;

        expect(named.length, equals(2));
        expect(named[0].paramName, equals('dep2'));
        expect(named[1].paramName, equals('dep3'));
      });

      test('should return empty list when no named dependencies', () {
        final config = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          dependencies: [
            InjectedDependency(
              type: const ImportableType(name: 'Dep1'),
              paramName: 'dep1',
              isPositional: true,
            ),
          ],
        );

        expect(config.namedDependencies, isEmpty);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final config1 = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          injectableType: InjectableType.factory,
          instanceName: 'test',
        );

        final config2 = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          injectableType: InjectableType.factory,
          instanceName: 'test',
        );

        expect(config1, equals(config2));
      });

      test('should not be equal when type differs', () {
        final config1 = DependencyConfig(type: type, typeImpl: typeImpl);
        final config2 = DependencyConfig(
          type: const ImportableType(name: 'Other'),
          typeImpl: typeImpl,
        );

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when injectableType differs', () {
        final config1 = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          injectableType: InjectableType.factory,
        );
        final config2 = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          injectableType: InjectableType.singleton,
        );

        expect(config1, isNot(equals(config2)));
      });
    });

    group('hashCode', () {
      test('should be same for equal configs', () {
        final config1 = DependencyConfig(type: type, typeImpl: typeImpl);
        final config2 = DependencyConfig(type: type, typeImpl: typeImpl);

        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should compute identityHash', () {
        final config = DependencyConfig(type: type, typeImpl: typeImpl);

        expect(config.identityHash, isA<int>());
      });

      test('identityHash should be stable', () {
        final config = DependencyConfig(type: type, typeImpl: typeImpl);

        final hash1 = config.identityHash;
        final hash2 = config.identityHash;

        expect(hash1, equals(hash2));
      });
    });

    group('JSON serialization', () {
      test('should serialize minimal config to JSON', () {
        final config = DependencyConfig(type: type, typeImpl: typeImpl);

        final json = config.toJson();

        expect(json['type'], isNotNull);
        expect(json['typeImpl'], isNotNull);
        expect(json['isAsync'], isFalse);
        expect(json['preResolve'], isFalse);
        expect(json['canBeConst'], isFalse);
        expect(json['injectableType'], equals(InjectableType.factory));
      });

      test('should not include null fields in JSON', () {
        final config = DependencyConfig(type: type, typeImpl: typeImpl);

        final json = config.toJson();

        expect(json.containsKey('instanceName'), isFalse);
        expect(json.containsKey('signalsReady'), isFalse);
        expect(json.containsKey('postConstruct'), isFalse);
        expect(json.containsKey('scope'), isFalse);
      });

      test('should round-trip through JSON', () {
        final original = DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          instanceName: 'test',
          environments: const ['dev', 'test'],
          isAsync: true,
          cache: true,
        );

        final json = original.toJson();
        final deserialized = DependencyConfig.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('toString', () {
      test('should return JSON representation', () {
        final config = DependencyConfig(type: type, typeImpl: typeImpl);

        final str = config.toString();

        expect(str, contains('DependencyConfig'));
        expect(str, isA<String>());
      });
    });
  });
}
