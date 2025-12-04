import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart' hide test;
import 'package:test/test.dart';

// Test classes
class TestService {}

class AnotherService {}

class ServiceWithDeps {
  final TestService testService;
  ServiceWithDeps(this.testService);
}

class DisposableService {
  bool disposed = false;
  void dispose() {
    disposed = true;
  }
}

class AsyncService {
  final String name;
  AsyncService(this.name);

  static Future<AsyncService> create() async {
    await Future.delayed(Duration(milliseconds: 10));
    return AsyncService('async');
  }
}

class ServiceWithParams {
  final String param1;
  final int param2;
  ServiceWithParams(this.param1, this.param2);
}

void main() {
  group('GetItHelper', () {
    late GetIt getIt;
    late GetItHelper helper;

    setUp(() {
      getIt = GetIt.asNewInstance();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('initialization', () {
      test('should create helper with environment string', () {
        helper = GetItHelper(getIt, 'dev');
        expect(helper.getIt, equals(getIt));
      });

      test('should create helper with custom environment filter', () {
        final filter = NoEnvOrContains('test');
        helper = GetItHelper(getIt, null, filter);
        expect(helper.getIt, equals(getIt));
      });

      test('should register environment filter as singleton', () {
        helper = GetItHelper(getIt, 'dev');
        expect(
          getIt.isRegistered<EnvironmentFilter>(
            instanceName: kEnvironmentsFilterName,
          ),
          isTrue,
        );
      });

      test('should register environments set as singleton', () {
        helper = GetItHelper(getIt, 'dev');
        expect(
          getIt.isRegistered<Set<String>>(instanceName: kEnvironmentsName),
          isTrue,
        );
        final envs = getIt<Set<String>>(instanceName: kEnvironmentsName);
        expect(envs, {'dev'});
      });

      test('should reuse existing environment filter', () {
        final filter1 = NoEnvOrContains('dev');
        helper = GetItHelper(getIt, null, filter1);
        final registered = getIt<EnvironmentFilter>(
          instanceName: kEnvironmentsFilterName,
        );
        expect(registered, equals(filter1));
      });

      test('should assert when both environment and filter are provided', () {
        expect(
          () => GetItHelper(getIt, 'dev', NoEnvOrContains('test')),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('call method', () {
      test('should get instance from GetIt', () {
        getIt.registerFactory<TestService>(() => TestService());
        helper = GetItHelper(getIt);

        final service = helper<TestService>();
        expect(service, isA<TestService>());
      });

      test('should get named instance from GetIt', () {
        getIt.registerFactory<TestService>(
          () => TestService(),
          instanceName: 'named',
        );
        helper = GetItHelper(getIt);

        final service = helper<TestService>(instanceName: 'named');
        expect(service, isA<TestService>());
      });

      test('should get instance with parameters', () {
        getIt.registerFactoryParam<ServiceWithParams, String, int>(
          (p1, p2) => ServiceWithParams(p1, p2),
        );
        helper = GetItHelper(getIt);

        final service = helper<ServiceWithParams>(
          param1: 'test',
          param2: 42,
        );
        expect(service.param1, 'test');
        expect(service.param2, 42);
      });
    });

    group('getAsync', () {
      test('should get async instance from GetIt', () async {
        getIt.registerSingletonAsync<AsyncService>(() async {
          await Future.delayed(Duration(milliseconds: 10));
          return AsyncService('test');
        });
        helper = GetItHelper(getIt);

        final service = await helper.getAsync<AsyncService>();
        expect(service, isA<AsyncService>());
        expect(service.name, 'test');
      });
    });

    group('factory', () {
      test('should register factory when environment matches', () {
        helper = GetItHelper(getIt, 'dev');
        helper.factory<TestService>(
          () => TestService(),
          registerFor: {'dev'},
        );

        expect(getIt.isRegistered<TestService>(), isTrue);
      });

      test('should not register factory when environment does not match', () {
        helper = GetItHelper(getIt, 'dev');
        helper.factory<TestService>(
          () => TestService(),
          registerFor: {'prod'},
        );

        expect(getIt.isRegistered<TestService>(), isFalse);
      });

      test('should register factory with instance name', () {
        helper = GetItHelper(getIt);
        helper.factory<TestService>(
          () => TestService(),
          instanceName: 'named',
        );

        expect(
          getIt.isRegistered<TestService>(instanceName: 'named'),
          isTrue,
        );
      });

      test('should register factory when registerFor is null', () {
        helper = GetItHelper(getIt, 'dev');
        helper.factory<TestService>(() => TestService());

        expect(getIt.isRegistered<TestService>(), isTrue);
      });
    });

    group('factoryCached', () {
      test('should register cached factory when environment matches', () {
        helper = GetItHelper(getIt, 'dev');
        helper.factoryCached<TestService>(
          () => TestService(),
          registerFor: {'dev'},
        );

        expect(getIt.isRegistered<TestService>(), isTrue);
        final instance1 = getIt<TestService>();
        final instance2 = getIt<TestService>();
        expect(identical(instance1, instance2), isTrue);
      });

      test(
        'should not register cached factory when environment does not match',
        () {
          helper = GetItHelper(getIt, 'prod');
          helper.factoryCached<TestService>(
            () => TestService(),
            registerFor: {'dev'},
          );

          expect(getIt.isRegistered<TestService>(), isFalse);
        },
      );
    });

    group('factoryAsync', () {
      test('should register async factory when environment matches', () async {
        helper = GetItHelper(getIt, 'dev');
        await helper.factoryAsync<AsyncService>(
          () async => AsyncService('test'),
          registerFor: {'dev'},
        );

        expect(getIt.isRegistered<AsyncService>(), isTrue);
      });

      test(
        'should pre-resolve async factory when preResolve is true',
        () async {
          helper = GetItHelper(getIt, 'dev');
          await helper.factoryAsync<AsyncService>(
            () async => AsyncService('test'),
            preResolve: true,
            registerFor: {'dev'},
          );

          final service = getIt<AsyncService>();
          expect(service.name, 'test');
        },
      );

      test('should not register when environment does not match', () async {
        helper = GetItHelper(getIt, 'prod');
        await helper.factoryAsync<AsyncService>(
          () async => AsyncService('test'),
          registerFor: {'dev'},
        );

        expect(getIt.isRegistered<AsyncService>(), isFalse);
      });
    });

    group('factoryCachedAsync', () {
      test('should register cached async factory', () async {
        helper = GetItHelper(getIt, 'dev');
        await helper.factoryCachedAsync<AsyncService>(
          () async => AsyncService('test'),
          registerFor: {'dev'},
        );

        expect(getIt.isRegistered<AsyncService>(), isTrue);
      });

      test('should pre-resolve cached async factory', () async {
        helper = GetItHelper(getIt);
        await helper.factoryCachedAsync<AsyncService>(
          () async => AsyncService('test'),
          preResolve: true,
        );

        final service1 = getIt<AsyncService>();
        final service2 = getIt<AsyncService>();
        expect(identical(service1, service2), isTrue);
      });
    });

    group('factoryParam', () {
      test('should register factory with parameters', () {
        helper = GetItHelper(getIt);
        helper.factoryParam<ServiceWithParams, String, int>(
          (p1, p2) => ServiceWithParams(p1, p2),
        );

        expect(getIt.isRegistered<ServiceWithParams>(), isTrue);
        final service = getIt<ServiceWithParams>(param1: 'test', param2: 42);
        expect(service.param1, 'test');
        expect(service.param2, 42);
      });

      test('should not register when environment does not match', () {
        helper = GetItHelper(getIt, 'dev');
        helper.factoryParam<ServiceWithParams, String, int>(
          (p1, p2) => ServiceWithParams(p1, p2),
          registerFor: {'prod'},
        );

        expect(getIt.isRegistered<ServiceWithParams>(), isFalse);
      });
    });

    group('factoryCachedParam', () {
      test('should register cached factory with parameters', () {
        helper = GetItHelper(getIt);
        helper.factoryCachedParam<ServiceWithParams, String, int>(
          (p1, p2) => ServiceWithParams(p1, p2),
        );

        expect(getIt.isRegistered<ServiceWithParams>(), isTrue);
      });
    });

    group('factoryParamAsync', () {
      test('should register async factory with parameters', () {
        helper = GetItHelper(getIt);
        helper.factoryParamAsync<ServiceWithParams, String, int>(
          (p1, p2) async => ServiceWithParams(p1!, p2!),
        );

        expect(getIt.isRegistered<ServiceWithParams>(), isTrue);
      });
    });

    group('factoryCachedParamAsync', () {
      test('should register cached async factory with parameters', () {
        helper = GetItHelper(getIt);
        helper.factoryCachedParamAsync<ServiceWithParams, String, int>(
          (p1, p2) async => ServiceWithParams(p1!, p2!),
        );

        expect(getIt.isRegistered<ServiceWithParams>(), isTrue);
      });
    });

    group('lazySingleton', () {
      test('should register lazy singleton', () {
        helper = GetItHelper(getIt);
        helper.lazySingleton<TestService>(() => TestService());

        expect(getIt.isRegistered<TestService>(), isTrue);
        final instance1 = getIt<TestService>();
        final instance2 = getIt<TestService>();
        expect(identical(instance1, instance2), isTrue);
      });

      test('should register lazy singleton with dispose callback', () async {
        helper = GetItHelper(getIt);
        helper.lazySingleton<DisposableService>(
          () => DisposableService(),
          dispose: (s) => s.dispose(),
        );
        final service = getIt<DisposableService>();
        expect(service.disposed, isFalse);
        await getIt.reset();
        expect(service.disposed, isTrue);
      });

      test('should not register when environment does not match', () {
        helper = GetItHelper(getIt, 'dev');
        helper.lazySingleton<TestService>(
          () => TestService(),
          registerFor: {'prod'},
        );

        expect(getIt.isRegistered<TestService>(), isFalse);
      });
    });

    group('lazySingletonAsync', () {
      test('should register lazy singleton async', () async {
        helper = GetItHelper(getIt);
        await helper.lazySingletonAsync<AsyncService>(
          () async => AsyncService('test'),
        );

        expect(getIt.isRegistered<AsyncService>(), isTrue);
      });

      test('should pre-resolve lazy singleton async', () async {
        helper = GetItHelper(getIt);
        await helper.lazySingletonAsync<AsyncService>(
          () async => AsyncService('test'),
          preResolve: true,
        );

        final service = getIt<AsyncService>();
        expect(service.name, 'test');
      });
    });

    group('singleton', () {
      test('should register singleton', () {
        helper = GetItHelper(getIt);
        helper.singleton<TestService>(() => TestService());

        expect(getIt.isRegistered<TestService>(), isTrue);
        final instance1 = getIt<TestService>();
        final instance2 = getIt<TestService>();
        expect(identical(instance1, instance2), isTrue);
      });

      test('should register singleton with signalsReady', () {
        helper = GetItHelper(getIt);
        helper.singleton<TestService>(
          () => TestService(),
          signalsReady: true,
        );

        expect(getIt.isRegistered<TestService>(), isTrue);
      });

      test('should not register when environment does not match', () {
        helper = GetItHelper(getIt, 'dev');
        helper.singleton<TestService>(
          () => TestService(),
          registerFor: {'prod'},
        );

        expect(getIt.isRegistered<TestService>(), isFalse);
      });
    });

    group('singletonAsync', () {
      test('should register singleton async', () async {
        helper = GetItHelper(getIt);
        await helper.singletonAsync<AsyncService>(
          () async => AsyncService('test'),
        );

        expect(getIt.isRegistered<AsyncService>(), isTrue);
      });

      test('should pre-resolve singleton async', () async {
        helper = GetItHelper(getIt);
        await helper.singletonAsync<AsyncService>(
          () async => AsyncService('test'),
          preResolve: true,
        );

        final service = getIt<AsyncService>();
        expect(service.name, 'test');
      });

      test('should register singleton async with dependencies', () async {
        helper = GetItHelper(getIt);
        helper.singletonAsync<TestService>(() async => TestService());

        await helper.singletonAsync<AsyncService>(
          () async => AsyncService('test'),
          dependsOn: [TestService],
        );

        expect(getIt.isRegistered<AsyncService>(), isTrue);
      });
    });

    group('singletonWithDependencies', () {
      test('should not register when environment does not match', () {
        helper = GetItHelper(getIt, 'dev');
        helper.singletonWithDependencies<TestService>(
          () => TestService(),
          registerFor: {'prod'},
        );

        expect(getIt.isRegistered<TestService>(), isFalse);
      });
    });

    group('initScope', () {
      test('should initialize scope synchronously', () {
        helper = GetItHelper(getIt);

        final result = helper.initScope(
          'testScope',
          init: (gh) {
            gh.factory<TestService>(() => TestService());
          },
        );

        expect(result, equals(getIt));
        expect(getIt.currentScopeName, 'testScope');
      });

      test('should register dependencies in scope', () {
        helper = GetItHelper(getIt);

        helper.initScope(
          'testScope',
          init: (gh) {
            gh.factory<TestService>(() => TestService());
          },
        );

        expect(getIt.isRegistered<TestService>(), isTrue);
      });

      test('should call dispose callback when scope is popped', () async {
        helper = GetItHelper(getIt);
        var disposed = false;

        helper.initScope(
          'testScope',
          init: (gh) {
            gh.factory<TestService>(() => TestService());
          },
          dispose: () {
            disposed = true;
          },
        );

        await getIt.popScope();
        expect(disposed, isTrue);
      });
    });

    group('initScopeAsync', () {
      test('should initialize scope asynchronously', () async {
        helper = GetItHelper(getIt);

        final result = await helper.initScopeAsync(
          'testScope',
          init: (gh) async {
            await Future.delayed(Duration(milliseconds: 10));
            gh.factory<TestService>(() => TestService());
          },
        );

        expect(result, equals(getIt));
        expect(getIt.currentScopeName, 'testScope');
      });

      test('should register async dependencies in scope', () async {
        helper = GetItHelper(getIt);

        await helper.initScopeAsync(
          'testScope',
          init: (gh) async {
            await gh.singletonAsync<AsyncService>(
              () async => AsyncService('test'),
              preResolve: true,
            );
          },
        );

        expect(getIt.isRegistered<AsyncService>(), isTrue);
      });

      test('should handle errors in async scope initialization', () async {
        helper = GetItHelper(getIt);

        expect(
          () => helper.initScopeAsync(
            'testScope',
            init: (gh) async {
              throw Exception('Test error');
            },
          ),
          throwsException,
        );
      });
    });
  });
}
