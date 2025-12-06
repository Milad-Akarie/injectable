import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:test/test.dart';

void main() {
  group('Sort by dependents test', () {
    test('should sort as [B,A,C]', () {
      final deps = [
        DependencyConfig.factory('A', deps: ['B']),
        DependencyConfig.singleton('B'),
        DependencyConfig.factory('C', deps: ['A']),
      ];
      final expectedResult = [
        DependencyConfig.singleton('B'),
        DependencyConfig.factory('A', deps: ['B']),
        DependencyConfig.factory('C', deps: ['A']),
      ];
      expect(sortDependencies(deps), expectedResult);
    });

    test(
      'Sorting with environments in mind, should sort as [B{prod},B{dev}},A{dev}]',
      () {
        final deps = [
          DependencyConfig.factory('A', deps: ['B'], envs: ['dev', 'prod']),
          DependencyConfig.factory('B', envs: ['prod']),
          DependencyConfig.factory('B', envs: ['dev']),
        ];
        final expectedResult = [
          DependencyConfig.factory('B', envs: ['dev']),
          DependencyConfig.factory('B', envs: ['prod']),
          DependencyConfig.factory('A', deps: ['B'], envs: ['dev', 'prod']),
        ];
        expect(sortDependencies(deps), expectedResult);
      },
    );

    test('should sort as [Dio,FakeUserApi,UserApi,UserRepository]', () {
      final deps = [
        DependencyConfig.singleton('Repository', deps: ['UserApi']),
        DependencyConfig.singleton(
          'UserApi',
          typeImpl: 'FakeUserApi',
          envs: ['test'],
          lazy: true,
        ),
        DependencyConfig.singleton(
          'UserApi',
          typeImpl: 'ImplUserApi',
          envs: ['dev'],
          deps: ['Dio'],
        ),
        DependencyConfig.singleton('Dio', lazy: true, envs: ['dev']),
      ];
      final expectedResult = [
        DependencyConfig.singleton('Dio', lazy: true, envs: ['dev']),
        DependencyConfig.singleton(
          'UserApi',
          typeImpl: 'FakeUserApi',
          envs: ['test'],
          lazy: true,
        ),
        DependencyConfig.singleton(
          'UserApi',
          typeImpl: 'ImplUserApi',
          envs: ['dev'],
          deps: ['Dio'],
        ),
        DependencyConfig.singleton('Repository', deps: ['UserApi']),
      ];
      expect(sortDependencies(deps), expectedResult);
    });

    test('should sort as [A,B]', () {
      final deps = [
        DependencyConfig.factory('AppServiceUser', deps: ['Service']),
        DependencyConfig.factory('Service', envs: ['dev']),
      ];
      final expectedResult = [
        DependencyConfig.factory('Service', envs: ['dev']),
        DependencyConfig.factory('AppServiceUser', deps: ['Service']),
      ];
      expect(sortDependencies(deps), expectedResult);
    });
  });

  group('Sort by dependents and order position test', () {
    test('should sort as [C,A,B]', () {
      final deps = [
        DependencyConfig.factory('A'),
        DependencyConfig.singleton('B', order: 1),
        DependencyConfig.factory('C', order: -1),
      ];
      final expectedResult = [
        DependencyConfig.factory('C', order: -1),
        DependencyConfig.factory('A'),
        DependencyConfig.singleton('B', order: 1),
      ];
      expect(sortDependencies(deps), expectedResult);
    });

    test('should sort as [C,A,B] (with deps)', () {
      final deps = [
        DependencyConfig.factory('A', deps: ['B']),
        DependencyConfig.singleton('B', order: 1),
        DependencyConfig.factory('C', deps: ['A'], order: -1),
      ];
      final expectedResult = [
        DependencyConfig.factory('C', deps: ['A'], order: -1),
        DependencyConfig.factory('A', deps: ['B']),
        DependencyConfig.singleton('B', order: 1),
      ];
      expect(sortDependencies(deps), expectedResult);
    });

    test(
      'Sorting with environments in mind, should sort as [B{prd},B{dev}},A{dev}]',
      () {
        final deps = [
          DependencyConfig.factory('A', deps: ['B'], envs: ['dev', 'prod']),
          DependencyConfig.factory('B', envs: ['prod'], order: 1),
          DependencyConfig.factory('B', envs: ['dev'], order: -1),
        ];
        final expectedResult = [
          DependencyConfig.factory('B', envs: ['dev'], order: -1),
          DependencyConfig.factory('A', deps: ['B'], envs: ['dev', 'prod']),
          DependencyConfig.factory('B', envs: ['prod'], order: 1),
        ];
        expect(sortDependencies(deps), expectedResult);
      },
    );

    test('should sort deep dependency chain correctly with orders', () {
      final deps = [
        DependencyConfig.factory('D', deps: ['C'], order: 10),
        DependencyConfig.factory('C', deps: ['B'], order: -5),
        DependencyConfig.factory('B', deps: ['A']),
        DependencyConfig.factory('A', order: -10),
      ];
      final expectedResult = [
        DependencyConfig.factory('A', order: -10),
        DependencyConfig.factory('C', deps: ['B'], order: -5),
        DependencyConfig.factory('B', deps: ['A']),
        DependencyConfig.factory('D', deps: ['C'], order: 10),
      ];
      expect(sortDependencies(deps), expectedResult);
    });
  });

  group('Sort complex dependency chains test', () {
    test('should sort long chain A->B->C->D', () {
      final deps = [
        DependencyConfig.factory('D', deps: ['C']),
        DependencyConfig.factory('A'),
        DependencyConfig.factory('C', deps: ['B']),
        DependencyConfig.factory('B', deps: ['A']),
      ];
      final expectedResult = [
        DependencyConfig.factory('A'),
        DependencyConfig.factory('B', deps: ['A']),
        DependencyConfig.factory('C', deps: ['B']),
        DependencyConfig.factory('D', deps: ['C']),
      ];
      expect(sortDependencies(deps), expectedResult);
    });

    test('should sort multiple independent chains', () {
      final deps = [
        DependencyConfig.factory('B', deps: ['A']),
        DependencyConfig.factory('D', deps: ['C']),
        DependencyConfig.factory('A'),
        DependencyConfig.factory('C'),
      ];
      final result = sortDependencies(deps);
      expect(result.length, 4);
      expect(
        result.indexOf(DependencyConfig.factory('A')) < result.indexOf(DependencyConfig.factory('B', deps: ['A'])),
        isTrue,
      );
      expect(
        result.indexOf(DependencyConfig.factory('C')) < result.indexOf(DependencyConfig.factory('D', deps: ['C'])),
        isTrue,
      );
    });

    test('should handle diamond dependency pattern', () {
      final deps = [
        DependencyConfig.factory('D', deps: ['B', 'C']),
        DependencyConfig.factory('B', deps: ['A']),
        DependencyConfig.factory('C', deps: ['A']),
        DependencyConfig.factory('A'),
      ];
      final result = sortDependencies(deps);
      expect(result.first, DependencyConfig.factory('A'));
      expect(result.last, DependencyConfig.factory('D', deps: ['B', 'C']));
    });

    test('should sort with multiple dependencies per item', () {
      final deps = [
        DependencyConfig.factory('E', deps: ['C', 'D']),
        DependencyConfig.factory('D', deps: ['A', 'B']),
        DependencyConfig.factory('C', deps: ['A']),
        DependencyConfig.factory('B'),
        DependencyConfig.factory('A'),
      ];
      final result = sortDependencies(deps);
      // A and B should come before C and D
      expect(
        result.indexOf(DependencyConfig.factory('A')) < result.indexOf(DependencyConfig.factory('C', deps: ['A'])),
        isTrue,
      );
      expect(
        result.indexOf(DependencyConfig.factory('A')) < result.indexOf(DependencyConfig.factory('D', deps: ['A', 'B'])),
        isTrue,
      );
      expect(
        result.indexOf(DependencyConfig.factory('B')) < result.indexOf(DependencyConfig.factory('D', deps: ['A', 'B'])),
        isTrue,
      );
      // C and D should come before E
      expect(
        result.indexOf(DependencyConfig.factory('C', deps: ['A'])) <
            result.indexOf(DependencyConfig.factory('E', deps: ['C', 'D'])),
        isTrue,
      );
      expect(
        result.indexOf(DependencyConfig.factory('D', deps: ['A', 'B'])) <
            result.indexOf(DependencyConfig.factory('E', deps: ['C', 'D'])),
        isTrue,
      );
    });
  });

  group('Sort with multiple environments test', () {
    test('should handle same type in different environments with dependencies', () {
      final deps = [
        DependencyConfig.factory('Client', deps: ['Config'], envs: ['prod']),
        DependencyConfig.factory('Client', deps: ['Config'], envs: ['dev']),
        DependencyConfig.factory('Config', envs: ['prod']),
        DependencyConfig.factory('Config', envs: ['dev']),
      ];
      final result = sortDependencies(deps);
      expect(result.length, 4);
      // Both Config instances should come before both Client instances
      final configProdIndex = result.indexOf(
        DependencyConfig.factory('Config', envs: ['prod']),
      );
      final configDevIndex = result.indexOf(
        DependencyConfig.factory('Config', envs: ['dev']),
      );
      final clientProdIndex = result.indexOf(
        DependencyConfig.factory('Client', deps: ['Config'], envs: ['prod']),
      );
      final clientDevIndex = result.indexOf(
        DependencyConfig.factory('Client', deps: ['Config'], envs: ['dev']),
      );
      expect(configProdIndex < clientProdIndex, isTrue);
      expect(configDevIndex < clientDevIndex, isTrue);
    });

    test('should handle cross-environment dependencies', () {
      final deps = [
        DependencyConfig.factory('A', deps: ['B'], envs: ['test']),
        DependencyConfig.factory('B', envs: ['dev', 'test']),
        DependencyConfig.factory('C', deps: ['B'], envs: ['dev']),
      ];
      final result = sortDependencies(deps);
      final bIndex = result.indexOf(
        DependencyConfig.factory('B', envs: ['dev', 'test']),
      );
      final aIndex = result.indexOf(
        DependencyConfig.factory('A', deps: ['B'], envs: ['test']),
      );
      final cIndex = result.indexOf(
        DependencyConfig.factory('C', deps: ['B'], envs: ['dev']),
      );
      expect(bIndex < aIndex, isTrue);
      expect(bIndex < cIndex, isTrue);
    });

    test('should sort when dependency has no environment but dependent has', () {
      final deps = [
        DependencyConfig.factory('Consumer', deps: ['Service'], envs: ['prod']),
        DependencyConfig.factory('Service'),
      ];
      final expectedResult = [
        DependencyConfig.factory('Service'),
        DependencyConfig.factory('Consumer', deps: ['Service'], envs: ['prod']),
      ];
      expect(sortDependencies(deps), expectedResult);
    });
  });

  group('Sort edge cases test', () {
    test('should handle empty list', () {
      final deps = <DependencyConfig>[];
      expect(sortDependencies(deps), isEmpty);
    });

    test('should handle single dependency', () {
      final deps = [DependencyConfig.factory('A')];
      expect(sortDependencies(deps), deps);
    });

    test('should preserve order with extreme order values', () {
      final deps = [
        DependencyConfig.factory('A', order: 1000),
        DependencyConfig.factory('B', order: -1000),
        DependencyConfig.factory('C'),
      ];
      final result = sortDependencies(deps);
      expect(result[0], DependencyConfig.factory('B', order: -1000));
      expect(result[1], DependencyConfig.factory('C'));
      expect(result[2], DependencyConfig.factory('A', order: 1000));
    });

    test('should handle very long dependency chain (10 levels)', () {
      final deps = [
        DependencyConfig.factory('J', deps: ['I']),
        DependencyConfig.factory('I', deps: ['H']),
        DependencyConfig.factory('H', deps: ['G']),
        DependencyConfig.factory('G', deps: ['F']),
        DependencyConfig.factory('F', deps: ['E']),
        DependencyConfig.factory('E', deps: ['D']),
        DependencyConfig.factory('D', deps: ['C']),
        DependencyConfig.factory('C', deps: ['B']),
        DependencyConfig.factory('B', deps: ['A']),
        DependencyConfig.factory('A'),
      ];
      final result = sortDependencies(deps);
      expect(result.first, DependencyConfig.factory('A'));
      expect(result.last, DependencyConfig.factory('J', deps: ['I']));
      // Verify proper ordering for each step
      for (var i = 1; i < result.length; i++) {
        // Each dependency should come after its dependencies
        if (result[i].dependencies.isNotEmpty) {
          for (var dep in result[i].dependencies) {
            final depConfig = result.firstWhere((d) => d.type.name == dep.type.name);
            expect(result.indexOf(depConfig) < i, isTrue);
          }
        }
      }
    });
  });

  group('Sort with mixed injectable types test', () {
    test('should sort singletons and factories with dependencies', () {
      final deps = [
        DependencyConfig.factory('FactoryService', deps: ['SingletonService']),
        DependencyConfig.singleton('SingletonService'),
        DependencyConfig.singleton('AnotherSingleton', deps: ['FactoryService']),
      ];
      final result = sortDependencies(deps);
      expect(
        result.indexOf(DependencyConfig.singleton('SingletonService')) <
            result.indexOf(DependencyConfig.factory('FactoryService', deps: ['SingletonService'])),
        isTrue,
      );
      expect(
        result.indexOf(DependencyConfig.factory('FactoryService', deps: ['SingletonService'])) <
            result.indexOf(DependencyConfig.singleton('AnotherSingleton', deps: ['FactoryService'])),
        isTrue,
      );
    });

    test('should sort lazy and eager singletons correctly', () {
      final deps = [
        DependencyConfig.factory('Consumer', deps: ['LazyService', 'EagerService']),
        DependencyConfig.singleton('EagerService'),
        DependencyConfig.singleton('LazyService', lazy: true),
      ];
      final result = sortDependencies(deps);
      final eagerIndex = result.indexOf(DependencyConfig.singleton('EagerService'));
      final lazyIndex = result.indexOf(DependencyConfig.singleton('LazyService', lazy: true));
      final consumerIndex = result.indexOf(
        DependencyConfig.factory('Consumer', deps: ['LazyService', 'EagerService']),
      );
      expect(eagerIndex < consumerIndex, isTrue);
      expect(lazyIndex < consumerIndex, isTrue);
    });
  });

  group('Sort with cache property test', () {
    test('should sort cached dependencies with other dependencies', () {
      final deps = [
        DependencyConfig.factory('CachedService', cache: true),
        DependencyConfig.factory('Consumer', deps: ['CachedService']),
      ];
      final expectedResult = [
        DependencyConfig.factory('CachedService', cache: true),
        DependencyConfig.factory('Consumer', deps: ['CachedService']),
      ];
      expect(sortDependencies(deps), expectedResult);
    });

    test('should handle mixed cache and non-cache dependencies', () {
      final deps = [
        DependencyConfig.factory('D', deps: ['C']),
        DependencyConfig.factory('C', deps: ['B'], cache: true),
        DependencyConfig.factory('B', deps: ['A']),
        DependencyConfig.factory('A', cache: true),
      ];
      final result = sortDependencies(deps);
      expect(result.first, DependencyConfig.factory('A', cache: true));
      expect(result.last, DependencyConfig.factory('D', deps: ['C']));
    });
  });

  group('Sort with order and environments combined test', () {
    test('should respect order even with environment constraints', () {
      final deps = [
        DependencyConfig.factory('C', envs: ['prod'], order: 10),
        DependencyConfig.factory('B', envs: ['dev'], order: 5),
        DependencyConfig.factory('A', envs: ['test'], order: -5),
      ];
      final result = sortDependencies(deps);
      expect(result[0], DependencyConfig.factory('A', envs: ['test'], order: -5));
      expect(result[1], DependencyConfig.factory('B', envs: ['dev'], order: 5));
      expect(result[2], DependencyConfig.factory('C', envs: ['prod'], order: 10));
    });

    test('should handle dependencies with order across environments', () {
      final deps = [
        DependencyConfig.factory('Service', envs: ['prod'], order: 1),
        DependencyConfig.factory('Service', envs: ['dev'], order: -1),
        DependencyConfig.factory('Consumer', deps: ['Service'], envs: ['dev', 'prod']),
      ];
      final result = sortDependencies(deps);
      final devServiceIndex = result.indexOf(
        DependencyConfig.factory('Service', envs: ['dev'], order: -1),
      );
      final consumerIndex = result.indexOf(
        DependencyConfig.factory('Consumer', deps: ['Service'], envs: ['dev', 'prod']),
      );
      final prodServiceIndex = result.indexOf(
        DependencyConfig.factory('Service', envs: ['prod'], order: 1),
      );
      expect(devServiceIndex < consumerIndex, isTrue);
      expect(consumerIndex < prodServiceIndex, isTrue);
    });
  });

  group('Sort with complex real-world scenarios test', () {
    test('should sort typical app initialization sequence', () {
      final deps = [
        DependencyConfig.factory('HomePage', deps: ['UserRepository', 'AuthService']),
        DependencyConfig.factory('UserRepository', deps: ['ApiClient', 'Database']),
        DependencyConfig.singleton('Database', order: -10),
        DependencyConfig.singleton('ApiClient', deps: ['NetworkConfig'], order: -5),
        DependencyConfig.singleton('NetworkConfig', order: -20),
        DependencyConfig.singleton('AuthService', deps: ['ApiClient', 'TokenStorage']),
        DependencyConfig.singleton('TokenStorage', order: -15),
      ];
      final result = sortDependencies(deps);

      // Network config should be first
      expect(result.first, DependencyConfig.singleton('NetworkConfig', order: -20));

      // HomePage should be last
      expect(result.last, DependencyConfig.factory('HomePage', deps: ['UserRepository', 'AuthService']));

      // ApiClient should come after NetworkConfig
      final apiIndex = result.indexOf(
        DependencyConfig.singleton('ApiClient', deps: ['NetworkConfig'], order: -5),
      );
      final networkIndex = result.indexOf(DependencyConfig.singleton('NetworkConfig', order: -20));
      expect(networkIndex < apiIndex, isTrue);

      // UserRepository should come after ApiClient and Database
      final repoIndex = result.indexOf(
        DependencyConfig.factory('UserRepository', deps: ['ApiClient', 'Database']),
      );
      final dbIndex = result.indexOf(DependencyConfig.singleton('Database', order: -10));
      expect(apiIndex < repoIndex, isTrue);
      expect(dbIndex < repoIndex, isTrue);
    });

    test('should handle multi-module dependency graph', () {
      final deps = [
        // Auth module
        DependencyConfig.factory('AuthModule', deps: ['TokenManager', 'AuthApi']),
        DependencyConfig.factory('TokenManager', deps: ['Storage']),
        DependencyConfig.factory('AuthApi', deps: ['HttpClient']),

        // Network module
        DependencyConfig.singleton('HttpClient', deps: ['NetworkInterceptor']),
        DependencyConfig.singleton('NetworkInterceptor'),

        // Storage module
        DependencyConfig.singleton('Storage'),

        // App module
        DependencyConfig.factory('App', deps: ['AuthModule', 'HttpClient']),
      ];
      final result = sortDependencies(deps);

      // Basic dependencies first
      expect(
        result.indexOf(DependencyConfig.singleton('NetworkInterceptor')) <
            result.indexOf(DependencyConfig.singleton('HttpClient', deps: ['NetworkInterceptor'])),
        isTrue,
      );
      expect(
        result.indexOf(DependencyConfig.singleton('Storage')) <
            result.indexOf(DependencyConfig.factory('TokenManager', deps: ['Storage'])),
        isTrue,
      );

      // App should be last
      expect(
        result.last,
        DependencyConfig.factory('App', deps: ['AuthModule', 'HttpClient']),
      );
    });
  });

  group('Sort with named instances test', () {
    test('should sort named instances with dependencies', () {
      final deps = [
        DependencyConfig(
          type: ImportableType(name: 'Consumer'),
          typeImpl: ImportableType(name: 'Consumer'),
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Service'),
              paramName: 'primaryService',
              instanceName: 'primary',
            ),
          ],
        ),
        DependencyConfig(
          type: ImportableType(name: 'Service'),
          typeImpl: ImportableType(name: 'ServiceImpl'),
          instanceName: 'primary',
        ),
        DependencyConfig(
          type: ImportableType(name: 'Service'),
          typeImpl: ImportableType(name: 'ServiceImpl'),
          instanceName: 'secondary',
        ),
      ];
      final result = sortDependencies(deps);
      expect(result.length, 3);
      // primary service should come before consumer
      final primaryIndex = result.indexWhere(
        (d) => d.type.name == 'Service' && d.instanceName == 'primary',
      );
      final consumerIndex = result.indexWhere((d) => d.type.name == 'Consumer');
      expect(primaryIndex < consumerIndex, isTrue);
    });

    test('should handle multiple named instances with complex dependencies', () {
      final deps = [
        DependencyConfig(
          type: ImportableType(name: 'Client'),
          typeImpl: ImportableType(name: 'Client'),
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Config'),
              paramName: 'prodConfig',
              instanceName: 'prod',
            ),
            InjectedDependency(
              type: ImportableType(name: 'Logger'),
              paramName: 'mainLogger',
              instanceName: 'main',
            ),
          ],
        ),
        DependencyConfig(
          type: ImportableType(name: 'Config'),
          typeImpl: ImportableType(name: 'ProdConfig'),
          instanceName: 'prod',
        ),
        DependencyConfig(
          type: ImportableType(name: 'Config'),
          typeImpl: ImportableType(name: 'DevConfig'),
          instanceName: 'dev',
        ),
        DependencyConfig(
          type: ImportableType(name: 'Logger'),
          typeImpl: ImportableType(name: 'ConsoleLogger'),
          instanceName: 'main',
        ),
      ];
      final result = sortDependencies(deps);
      expect(result.length, 4);

      final prodConfigIndex = result.indexWhere(
        (d) => d.type.name == 'Config' && d.instanceName == 'prod',
      );
      final loggerIndex = result.indexWhere(
        (d) => d.type.name == 'Logger' && d.instanceName == 'main',
      );
      final clientIndex = result.indexWhere((d) => d.type.name == 'Client');

      expect(prodConfigIndex < clientIndex, isTrue);
      expect(loggerIndex < clientIndex, isTrue);
    });

    test('should handle named instances with environments', () {
      final deps = [
        DependencyConfig(
          type: ImportableType(name: 'Service'),
          typeImpl: ImportableType(name: 'ServiceImpl'),
          instanceName: 'primary',
          environments: ['prod'],
        ),
        DependencyConfig(
          type: ImportableType(name: 'Service'),
          typeImpl: ImportableType(name: 'ServiceImpl'),
          instanceName: 'primary',
          environments: ['dev'],
        ),
        DependencyConfig(
          type: ImportableType(name: 'Consumer'),
          typeImpl: ImportableType(name: 'Consumer'),
          environments: ['dev'],
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Service'),
              paramName: 'service',
              instanceName: 'primary',
            ),
          ],
        ),
      ];
      final result = sortDependencies(deps);
      expect(result.length, 3);

      final devServiceIndex = result.indexWhere(
        (d) => d.type.name == 'Service' && d.instanceName == 'primary' && d.environments.contains('dev'),
      );
      final consumerIndex = result.indexWhere(
        (d) => d.type.name == 'Consumer' && d.environments.contains('dev'),
      );

      expect(devServiceIndex < consumerIndex, isTrue);
    });
  });

  group('Sort with mixed configurations test', () {
    test('should handle dependencies with varying order positions and environments', () {
      final deps = [
        DependencyConfig.factory('Z', envs: ['prod'], order: 100),
        DependencyConfig.factory('A', envs: ['dev'], order: -100),
        DependencyConfig.factory('M', deps: ['A'], envs: ['dev']),
        DependencyConfig.singleton('B', order: 50),
      ];
      final result = sortDependencies(deps);

      expect(result.first, DependencyConfig.factory('A', envs: ['dev'], order: -100));
      expect(result.last, DependencyConfig.factory('Z', envs: ['prod'], order: 100));
    });

    test('should sort dependencies with multiple overlapping environments', () {
      final deps = [
        DependencyConfig.factory('Service', envs: ['dev', 'test']),
        DependencyConfig.factory('Client', deps: ['Service'], envs: ['dev']),
        DependencyConfig.factory('Consumer', deps: ['Service'], envs: ['test']),
      ];
      final result = sortDependencies(deps);

      final serviceIndex = result.indexOf(
        DependencyConfig.factory('Service', envs: ['dev', 'test']),
      );
      final clientIndex = result.indexOf(
        DependencyConfig.factory('Client', deps: ['Service'], envs: ['dev']),
      );
      final consumerIndex = result.indexOf(
        DependencyConfig.factory('Consumer', deps: ['Service'], envs: ['test']),
      );

      expect(serviceIndex < clientIndex, isTrue);
      expect(serviceIndex < consumerIndex, isTrue);
    });

    test('should handle mixture of lazy and eager singletons with factories', () {
      final deps = [
        DependencyConfig.factory('Factory1', deps: ['EagerSingleton', 'LazySingleton']),
        DependencyConfig.singleton('EagerSingleton', deps: ['BaseService']),
        DependencyConfig.singleton('LazySingleton', lazy: true, deps: ['BaseService']),
        DependencyConfig.singleton('BaseService'),
      ];
      final result = sortDependencies(deps);

      expect(result.first, DependencyConfig.singleton('BaseService'));
      expect(result.last, DependencyConfig.factory('Factory1', deps: ['EagerSingleton', 'LazySingleton']));
    });

    test('should handle wide dependency tree (one parent, many children)', () {
      final deps = [
        DependencyConfig.factory('Parent', deps: ['Child1', 'Child2', 'Child3', 'Child4']),
        DependencyConfig.factory('Child1'),
        DependencyConfig.factory('Child2'),
        DependencyConfig.factory('Child3'),
        DependencyConfig.factory('Child4'),
      ];
      final result = sortDependencies(deps);

      expect(result.last, DependencyConfig.factory('Parent', deps: ['Child1', 'Child2', 'Child3', 'Child4']));

      // All children should come before parent
      final parentIndex = result.indexOf(
        DependencyConfig.factory('Parent', deps: ['Child1', 'Child2', 'Child3', 'Child4']),
      );
      expect(result.indexOf(DependencyConfig.factory('Child1')) < parentIndex, isTrue);
      expect(result.indexOf(DependencyConfig.factory('Child2')) < parentIndex, isTrue);
      expect(result.indexOf(DependencyConfig.factory('Child3')) < parentIndex, isTrue);
      expect(result.indexOf(DependencyConfig.factory('Child4')) < parentIndex, isTrue);
    });
  });

  group('hasAsyncDependency', () {
    test('should return `false` when there are no dependencies', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
      );
      final allDeps = [dep];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.hasAsyncDependency(dep), isFalse);
    });

    test('should return `false` when all deps are not async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Fizz'),
          typeImpl: ImportableType(name: 'Fizz'),
          injectableType: InjectableType.factory,
        ),
      ];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.hasAsyncDependency(dep), isFalse);
    });

    test('should return `false` for a missing dependency', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
        ],
      );
      final allDeps = <DependencyConfig>[dep];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.hasAsyncDependency(dep), isFalse);
    });

    test('should return `true` when at least one dep is async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
            instanceName: 'buzzImpl',
          ),
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Fizz'),
          typeImpl: ImportableType(name: 'Fizz'),
          injectableType: InjectableType.factory,
          isAsync: true,
        ),
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          instanceName: 'buzzImpl',
        ),
      ];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.hasAsyncDependency(dep), isTrue);
    });

    test('should return `true` when a named instance dep is async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
            instanceName: 'buzzImpl',
          ),
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Fizz'),
          typeImpl: ImportableType(name: 'Fizz'),
          injectableType: InjectableType.factory,
        ),
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          instanceName: 'buzzImpl',
          isAsync: true,
        ),
      ];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.hasAsyncDependency(dep), isTrue);
    });

    test('should return `true` when a transitive dep is async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Fizz'),
          typeImpl: ImportableType(name: 'Fizz'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Buzz'),
              paramName: 'buzz',
              instanceName: 'buzzImpl',
            ),
          ],
        ),
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          instanceName: 'buzzImpl',
          isAsync: true,
        ),
      ];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.hasAsyncDependency(dep), isTrue);
    });
  });

  group('isAsyncOrHasAsyncDependency', () {
    test('should return `false` when dep lookup misses', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final depSet = DependencyList(dependencies: <DependencyConfig>[]);
      expect(depSet.isAsyncOrHasAsyncDependency(iDep), isFalse);
    });

    test('should return `false` when not async and no deps', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        isAsync: false,
      );
      final allDeps = [dep];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.isAsyncOrHasAsyncDependency(iDep), isFalse);
    });
    test('should return `false` when async but preResolve is true', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        isAsync: true,
        preResolve: true,
      );
      final allDeps = [dep];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.isAsyncOrHasAsyncDependency(iDep), isFalse);
    });

    test('should return `true` when async', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        isAsync: true,
      );
      final allDeps = [dep];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.isAsyncOrHasAsyncDependency(iDep), isTrue);
    });

    test('should return `false` when not async and no async deps', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
          ),
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
        ),
      ];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.isAsyncOrHasAsyncDependency(iDep), isFalse);
    });

    test('should return `true` when has an async deps', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
          ),
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          isAsync: true,
        ),
      ];
      final depSet = DependencyList(dependencies: allDeps);
      expect(depSet.isAsyncOrHasAsyncDependency(iDep), isTrue);
    });
  });

  group('lookupDependency', () {
    test('should return `null` when dep is not found', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final allDeps = <DependencyConfig>[];
      expect(lookupDependency(iDep, allDeps), isNull);
    });

    test('should find and return dep', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
      );
      final allDeps = [dep];
      expect(lookupDependency(iDep, allDeps), same(dep));
    });

    test('should return `null` when named dep is not found', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
        instanceName: 'fizzy',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        instanceName: 'fizzBuzz',
      );
      final allDeps = [dep];
      expect(lookupDependency(iDep, allDeps), isNull);
    });

    test('should find and return named dep', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        instanceName: 'fizzImpl',
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        instanceName: 'fizzImpl',
      );
      final allDeps = [dep];
      expect(lookupDependency(iDep, allDeps), same(dep));
    });
  });

  group('Complex sorting scenarios for full coverage', () {
    test('should handle factory params in dependency chain', () {
      final dep1 = DependencyConfig(
        type: const ImportableType(name: 'Service'),
        typeImpl: const ImportableType(name: 'Service'),
      );
      final dep2 = DependencyConfig(
        type: const ImportableType(name: 'Consumer'),
        typeImpl: const ImportableType(name: 'Consumer'),
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Service'),
            paramName: 'service',
            isFactoryParam: true,
          ),
        ],
      );
      final result = sortDependencies([dep2, dep1]);
      // Consumer can be sorted even without Service since it's a factory param
      expect(result, contains(dep2));
    });

    test('should handle dependencies with empty environments checking all variants', () {
      final dep1 = DependencyConfig(
        type: const ImportableType(name: 'SharedService'),
        typeImpl: const ImportableType(name: 'SharedService'),
        environments: const ['dev'],
      );
      final dep2 = DependencyConfig(
        type: const ImportableType(name: 'SharedService'),
        typeImpl: const ImportableType(name: 'SharedService'),
        environments: const ['prod'],
      );
      final consumer = DependencyConfig(
        type: const ImportableType(name: 'Consumer'),
        typeImpl: const ImportableType(name: 'Consumer'),
        environments: const [], // Empty environments - checks all
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'SharedService'),
            paramName: 'service',
          ),
        ],
      );
      final result = sortDependencies([consumer, dep1, dep2]);
      // Both SharedService variants should come before Consumer
      final dep1Index = result.indexOf(dep1);
      final dep2Index = result.indexOf(dep2);
      final consumerIndex = result.indexOf(consumer);
      expect(dep1Index < consumerIndex, isTrue);
      expect(dep2Index < consumerIndex, isTrue);
    });

    test('should handle partial environment matches - not all envs found', () {
      final dep1 = DependencyConfig(
        type: const ImportableType(name: 'Config'),
        typeImpl: const ImportableType(name: 'Config'),
        environments: const ['dev'],
      );
      final dep2 = DependencyConfig(
        type: const ImportableType(name: 'Config'),
        typeImpl: const ImportableType(name: 'Config'),
        environments: const ['prod'],
      );
      final consumer = DependencyConfig(
        type: const ImportableType(name: 'Service'),
        typeImpl: const ImportableType(name: 'Service'),
        environments: const ['dev', 'prod'],
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Config'),
            paramName: 'config',
          ),
        ],
      );
      final result = sortDependencies([consumer, dep1, dep2]);
      // Config in both dev and prod, should satisfy consumer
      expect(result, hasLength(3));
      final consumerIndex = result.indexOf(consumer);
      expect(result.indexOf(dep1) < consumerIndex, isTrue);
      expect(result.indexOf(dep2) < consumerIndex, isTrue);
    });

    test('should handle environment loop where lookup returns null', () {
      // This tests dependency with environments not fully available
      final dep1 = DependencyConfig(
        type: const ImportableType(name: 'Database'),
        typeImpl: const ImportableType(name: 'Database'),
        environments: const ['prod'],
      );
      final result = sortDependencies([dep1]);
      expect(result, contains(dep1));
    });

    test('should handle foundForEnvs matching all environments', () {
      final dep1 = DependencyConfig(
        type: const ImportableType(name: 'Logger'),
        typeImpl: const ImportableType(name: 'Logger'),
        environments: const ['dev', 'prod'],
      );
      final consumer = DependencyConfig(
        type: const ImportableType(name: 'Service'),
        typeImpl: const ImportableType(name: 'Service'),
        environments: const ['dev', 'prod'],
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Logger'),
            paramName: 'logger',
          ),
        ],
      );
      final result = sortDependencies([consumer, dep1]);
      // Logger available in both dev and prod
      final loggerIndex = result.indexOf(dep1);
      final serviceIndex = result.indexOf(consumer);
      expect(loggerIndex < serviceIndex, isTrue);
    });

    test('should handle dependency lookup in unSorted returning null', () {
      final depA = DependencyConfig.factory('A');
      final depB = DependencyConfig.factory('B', deps: ['A']);
      final depC = DependencyConfig.factory('C', deps: ['B']);

      final result = sortDependencies([depC, depB, depA]);

      expect(result[0].type.name, 'A');
      expect(result[1].type.name, 'B');
      expect(result[2].type.name, 'C');
    });

    test('should handle recursive sorting with difference', () {
      // Tests the recursive _sortByDependents call
      final depA = DependencyConfig.factory('A');
      final depB = DependencyConfig.factory('B', deps: ['A']);
      final depC = DependencyConfig.factory('C', deps: ['B']);
      final depD = DependencyConfig.factory('D', deps: ['C']);
      final depE = DependencyConfig.factory('E', deps: ['D']);

      final result = sortDependencies([depE, depD, depC, depB, depA]);

      expect(result[0].type.name, 'A');
      expect(result[1].type.name, 'B');
      expect(result[2].type.name, 'C');
      expect(result[3].type.name, 'D');
      expect(result[4].type.name, 'E');
    });

    test('should handle complex multi-environment scenario', () {
      final sharedBase = DependencyConfig(
        type: const ImportableType(name: 'Base'),
        typeImpl: const ImportableType(name: 'Base'),
        environments: const ['dev', 'test', 'prod'],
      );
      final devOnly = DependencyConfig(
        type: const ImportableType(name: 'DevService'),
        typeImpl: const ImportableType(name: 'DevService'),
        environments: const ['dev'],
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Base'),
            paramName: 'base',
          ),
        ],
      );
      final prodOnly = DependencyConfig(
        type: const ImportableType(name: 'ProdService'),
        typeImpl: const ImportableType(name: 'ProdService'),
        environments: const ['prod'],
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Base'),
            paramName: 'base',
          ),
        ],
      );

      final result = sortDependencies([prodOnly, devOnly, sharedBase]);

      final baseIndex = result.indexOf(sharedBase);
      final devIndex = result.indexOf(devOnly);
      final prodIndex = result.indexOf(prodOnly);

      expect(baseIndex < devIndex, isTrue);
      expect(baseIndex < prodIndex, isTrue);
    });

    test('should handle empty environments with multiple matching deps', () {
      final dep1 = DependencyConfig(
        type: const ImportableType(name: 'Plugin'),
        typeImpl: const ImportableType(name: 'Plugin'),
        instanceName: 'v1',
        environments: const ['old'],
      );
      final dep2 = DependencyConfig(
        type: const ImportableType(name: 'Plugin'),
        typeImpl: const ImportableType(name: 'Plugin'),
        instanceName: 'v2',
        environments: const ['new'],
      );
      final dep3 = DependencyConfig(
        type: const ImportableType(name: 'Plugin'),
        typeImpl: const ImportableType(name: 'Plugin'),
        instanceName: 'v3',
        environments: const ['latest'],
      );
      final consumer = DependencyConfig(
        type: const ImportableType(name: 'App'),
        typeImpl: const ImportableType(name: 'App'),
        environments: const [], // needs all Plugin versions
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Plugin'),
            paramName: 'plugin',
            instanceName: 'v1',
          ),
        ],
      );

      final result = sortDependencies([consumer, dep3, dep2, dep1]);

      expect(result.indexOf(dep1) < result.indexOf(consumer), isTrue);
    });

    test('should handle deps.every returning true when all in sorted', () {
      final base1 = DependencyConfig(
        type: const ImportableType(name: 'Base'),
        typeImpl: const ImportableType(name: 'Base'),
        environments: const ['env1'],
      );
      final base2 = DependencyConfig(
        type: const ImportableType(name: 'Base'),
        typeImpl: const ImportableType(name: 'Base'),
        environments: const ['env2'],
      );
      final consumer = DependencyConfig(
        type: const ImportableType(name: 'Consumer'),
        typeImpl: const ImportableType(name: 'Consumer'),
        environments: const [], // check all
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Base'),
            paramName: 'base',
          ),
        ],
      );

      final result = sortDependencies([consumer, base2, base1]);

      final consumerIndex = result.indexOf(consumer);
      expect(result.indexOf(base1) < consumerIndex, isTrue);
      expect(result.indexOf(base2) < consumerIndex, isTrue);
    });
  });

  group('DependencyList caching behavior', () {
    test('should cache async dependencies map on first access', () {
      final asyncDep = DependencyConfig(
        type: const ImportableType(name: 'AsyncService'),
        typeImpl: const ImportableType(name: 'AsyncService'),
        isAsync: true,
      );
      final dep = DependencyConfig(
        type: const ImportableType(name: 'Consumer'),
        typeImpl: const ImportableType(name: 'Consumer'),
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'AsyncService'),
            paramName: 'asyncService',
          ),
        ],
      );
      final list = DependencyList(dependencies: [asyncDep, dep]);

      // First call initializes the map
      expect(list.hasAsyncDependency(dep), isTrue);

      // Second call should use cached map
      expect(list.hasAsyncDependency(dep), isTrue);

      // Verify both methods work with cache
      final iDep = InjectedDependency(
        type: const ImportableType(name: 'AsyncService'),
        paramName: 'asyncService',
      );
      expect(list.isAsyncOrHasAsyncDependency(iDep), isTrue);
    });
  });

  group('typeRefer with record types test', () {
    test('should create record type reference with positional fields', () {
      const type = ImportableType.record(
        name: '',
        typeArguments: [
          ImportableType(name: 'String'),
          ImportableType(name: 'int'),
        ],
      );
      final ref = typeRefer(type);
      expect(ref, isA<RecordType>());
    });

    test('should create record type reference with named fields', () {
      const type = ImportableType.record(
        name: '',
        typeArguments: [
          ImportableType(name: 'String', nameInRecord: 'name'),
          ImportableType(name: 'int', nameInRecord: 'age'),
        ],
      );
      final ref = typeRefer(type);
      expect(ref, isA<RecordType>());
    });

    test('should create record type with mixed positional and named fields', () {
      const type = ImportableType.record(
        name: '',
        typeArguments: [
          ImportableType(name: 'String'),
          ImportableType(name: 'int', nameInRecord: 'count'),
          ImportableType(name: 'bool', nameInRecord: 'enabled'),
        ],
      );
      final ref = typeRefer(type);
      expect(ref, isA<RecordType>());
    });

    test('should create nullable record type', () {
      const type = ImportableType.record(
        name: '',
        isNullable: true,
        typeArguments: [
          ImportableType(name: 'String'),
        ],
      );
      final ref = typeRefer(type) as RecordType;
      expect(ref.isNullable, isTrue);
    });

    test('should filter positional fields correctly in record type', () {
      const type = ImportableType.record(
        name: '',
        typeArguments: [
          ImportableType(name: 'String'),
          ImportableType(name: 'int'),
          ImportableType(name: 'bool', nameInRecord: 'flag'),
        ],
      );
      final ref = typeRefer(type) as RecordType;
      // Should have 2 positional fields (String and int)
      expect(ref.positionalFieldTypes.length, equals(2));
    });

    test('should create namedFieldTypes map correctly', () {
      const type = ImportableType.record(
        name: '',
        typeArguments: [
          ImportableType(name: 'String', nameInRecord: 'name'),
          ImportableType(name: 'int', nameInRecord: 'age'),
        ],
      );
      final ref = typeRefer(type) as RecordType;
      expect(ref.namedFieldTypes.length, equals(2));
      expect(ref.namedFieldTypes.containsKey('name'), isTrue);
      expect(ref.namedFieldTypes.containsKey('age'), isTrue);
    });
  });

  group('Sorting edge cases for complete coverage', () {
    test('should handle case where deps.every returns true path', () {
      // This tests line 118: if (deps.every(sorted.contains))
      final shared1 = DependencyConfig(
        type: const ImportableType(name: 'Shared'),
        typeImpl: const ImportableType(name: 'Shared'),
        environments: const ['env1'],
      );
      final shared2 = DependencyConfig(
        type: const ImportableType(name: 'Shared'),
        typeImpl: const ImportableType(name: 'Shared'),
        environments: const ['env2'],
      );
      final consumer = DependencyConfig(
        type: const ImportableType(name: 'Consumer'),
        typeImpl: const ImportableType(name: 'Consumer'),
        environments: const [],
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Shared'),
            paramName: 'shared',
          ),
        ],
      );

      final result = sortDependencies([consumer, shared1, shared2]);

      // Both Shared deps should come before Consumer
      expect(result.indexOf(shared1) < result.indexOf(consumer), isTrue);
      expect(result.indexOf(shared2) < result.indexOf(consumer), isTrue);
    });

    test('should test the else branch incrementing foundForEnvs', () {
      // Tests line 128: foundForEnvs++
      final serviceDev = DependencyConfig(
        type: const ImportableType(name: 'Service'),
        typeImpl: const ImportableType(name: 'Service'),
        environments: const ['dev'],
      );
      final serviceProd = DependencyConfig(
        type: const ImportableType(name: 'Service'),
        typeImpl: const ImportableType(name: 'Service'),
        environments: const ['prod'],
      );
      final consumer = DependencyConfig(
        type: const ImportableType(name: 'Consumer'),
        typeImpl: const ImportableType(name: 'Consumer'),
        environments: const ['dev', 'prod'],
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Service'),
            paramName: 'service',
          ),
        ],
      );

      final result = sortDependencies([consumer, serviceProd, serviceDev]);

      expect(result.indexOf(serviceDev) < result.indexOf(consumer), isTrue);
      expect(result.indexOf(serviceProd) < result.indexOf(consumer), isTrue);
    });

    test('should test foundForEnvs == dep.environments.length path', () {
      // Tests line 132: if (foundForEnvs == dep.environments.length)
      final base = DependencyConfig.factory('Base');
      final multiEnv = DependencyConfig(
        type: const ImportableType(name: 'MultiEnv'),
        typeImpl: const ImportableType(name: 'MultiEnv'),
        environments: const ['a', 'b', 'c'],
        dependencies: [
          InjectedDependency(
            type: const ImportableType(name: 'Base'),
            paramName: 'base',
          ),
        ],
      );

      final result = sortDependencies([multiEnv, base]);

      expect(result.indexOf(base) < result.indexOf(multiEnv), isTrue);
    });
  });
}
