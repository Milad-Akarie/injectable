import 'package:injectable/injectable.dart' as inj;
import 'package:injectable/injectable.dart' hide test;
import 'package:test/test.dart';

void main() {
  group('InjectableInit', () {
    test('should create with default values', () {
      const init = InjectableInit();

      expect(init.generateForDir, ['lib']);
      expect(init.preferRelativeImports, false);
      expect(init.initializerName, 'init');
      expect(init.rootDir, isNull);
      expect(init.asExtension, true);
      expect(init.ignoreUnregisteredTypes, isEmpty);
      expect(init.ignoreUnregisteredTypesInPackages, isEmpty);
      expect(init.throwOnMissingDependencies, false);
      expect(init.includeMicroPackages, true);
      expect(init.externalPackageModulesBefore, isNull);
      expect(init.externalPackageModulesAfter, isNull);
      expect(init.usesConstructorCallback, false);
      expect(init.generateAccessors, false);
      expect(init.generateForEnvironments, isEmpty);
    });

    test('should create with custom values', () {
      const init = InjectableInit(
        generateForDir: ['lib', 'test'],
        preferRelativeImports: true,
        initializerName: 'customInit',
        rootDir: '/custom/path',
        asExtension: false,
        ignoreUnregisteredTypes: [String, int],
        ignoreUnregisteredTypesInPackages: ['package:test'],
        throwOnMissingDependencies: true,
        includeMicroPackages: false,
        usesConstructorCallback: true,
        generateAccessors: true,
        generateForEnvironments: {dev, prod},
      );

      expect(init.generateForDir, ['lib', 'test']);
      expect(init.preferRelativeImports, true);
      expect(init.initializerName, 'customInit');
      expect(init.rootDir, '/custom/path');
      expect(init.asExtension, false);
      expect(init.ignoreUnregisteredTypes, [String, int]);
      expect(init.ignoreUnregisteredTypesInPackages, ['package:test']);
      expect(init.throwOnMissingDependencies, true);
      expect(init.includeMicroPackages, false);
      expect(init.usesConstructorCallback, true);
      expect(init.generateAccessors, true);
      expect(init.generateForEnvironments, {dev, prod});
    });

    test('microPackage constructor should set correct defaults', () {
      const init = InjectableInit.microPackage();

      expect(init.generateForDir, ['lib']);
      expect(init.preferRelativeImports, false);
      expect(init.initializerName, 'init');
      expect(init.rootDir, isNull);
      expect(init.asExtension, false);
      expect(init.includeMicroPackages, false);
      expect(init.generateAccessors, false);
    });

    test('injectableInit const should be InjectableInit with defaults', () {
      expect(injectableInit, isA<InjectableInit>());
      expect(injectableInit.asExtension, true);
    });

    test('microPackageInit const should be InjectableInit.microPackage', () {
      expect(microPackageInit, isA<InjectableInit>());
      expect(microPackageInit.asExtension, false);
      expect(microPackageInit.includeMicroPackages, false);
    });
  });

  group('Injectable', () {
    test('should create with default values', () {
      const inj = Injectable();

      expect(inj.as, isNull);
      expect(inj.env, isNull);
      expect(inj.order, isNull);
      expect(inj.scope, isNull);
      expect(inj.cache, false);
    });

    test('should create with custom values', () {
      const inj = Injectable(
        as: String,
        env: ['dev', 'test'],
        order: 5,
        scope: 'customScope',
        cache: true,
      );

      expect(inj.as, String);
      expect(inj.env, ['dev', 'test']);
      expect(inj.order, 5);
      expect(inj.scope, 'customScope');
      expect(inj.cache, true);
    });

    test('injectable const should be Injectable with defaults', () {
      expect(injectable, isA<Injectable>());
      expect(injectable.cache, false);
    });
  });

  group('Singleton', () {
    test('should create with default values', () {
      const sing = Singleton();

      expect(sing.signalsReady, isNull);
      expect(sing.dependsOn, isNull);
      expect(sing.dispose, isNull);
      expect(sing.as, isNull);
      expect(sing.env, isNull);
      expect(sing.scope, isNull);
      expect(sing.order, isNull);
    });

    test('should create with custom values', () {
      void disposeFunc(dynamic instance) {}

      final sing = Singleton(
        signalsReady: true,
        dependsOn: const [String, int],
        dispose: disposeFunc,
        as: Object,
        env: const ['dev'],
        scope: 'testScope',
        order: 3,
      );

      expect(sing.signalsReady, true);
      expect(sing.dependsOn, const [String, int]);
      expect(sing.dispose, disposeFunc);
      expect(sing.as, Object);
      expect(sing.env, const ['dev']);
      expect(sing.scope, 'testScope');
      expect(sing.order, 3);
    });

    test('singleton const should be Singleton with defaults', () {
      expect(singleton, isA<Singleton>());
      expect(singleton.signalsReady, isNull);
    });
  });

  group('LazySingleton', () {
    test('should create with default values', () {
      const lazy = LazySingleton();

      expect(lazy.dispose, isNull);
      expect(lazy.as, isNull);
      expect(lazy.env, isNull);
      expect(lazy.scope, isNull);
      expect(lazy.order, isNull);
    });

    test('should create with custom values', () {
      void disposeFunc(dynamic instance) {}

      final lazy = LazySingleton(
        dispose: disposeFunc,
        as: Object,
        env: const ['prod'],
        scope: 'lazyScope',
        order: 7,
      );

      expect(lazy.dispose, disposeFunc);
      expect(lazy.as, Object);
      expect(lazy.env, const ['prod']);
      expect(lazy.scope, 'lazyScope');
      expect(lazy.order, 7);
    });

    test('lazySingleton const should be LazySingleton with defaults', () {
      expect(lazySingleton, isA<LazySingleton>());
      expect(lazySingleton.dispose, isNull);
    });
  });

  group('Named', () {
    test('should create with string name', () {
      const n = Named('testName');

      expect(n.name, 'testName');
      expect(n.type, isNull);
    });

    test('should create with type using from constructor', () {
      const n = Named.from(String);

      expect(n.name, isNull);
      expect(n.type, String);
    });

    test('named const should be Named with empty string', () {
      expect(named, isA<Named>());
      expect(named.name, '');
    });
  });

  group('Environment', () {
    test('should create with custom name', () {
      const env = Environment('staging');

      expect(env.name, 'staging');
    });

    test('should have preset constants', () {
      expect(Environment.dev, 'dev');
      expect(Environment.prod, 'prod');
      expect(Environment.test, 'test');
    });

    test('dev const should be Environment with dev name', () {
      expect(dev, isA<Environment>());
      expect(dev.name, Environment.dev);
    });

    test('prod const should be Environment with prod name', () {
      expect(prod, isA<Environment>());
      expect(prod.name, Environment.prod);
    });

    test('test const should be Environment with test name', () {
      expect(inj.test, isA<Environment>());
      expect(inj.test.name, Environment.test);
    });
  });

  group('FactoryMethod', () {
    test('should create with default values', () {
      const fm = FactoryMethod();

      expect(fm.preResolve, false);
    });

    test('should create with preResolve true', () {
      const fm = FactoryMethod(preResolve: true);

      expect(fm.preResolve, true);
    });

    test('factoryMethod const should be FactoryMethod with defaults', () {
      expect(factoryMethod, isA<FactoryMethod>());
      expect(factoryMethod.preResolve, false);
    });
  });

  group('FactoryParam', () {
    test('factoryParam const should be FactoryParam', () {
      expect(factoryParam, isA<FactoryParam>());
    });
  });

  group('IgnoreParam', () {
    test('ignoreParam const should be IgnoreParam', () {
      expect(ignoreParam, isA<IgnoreParam>());
    });
  });

  group('Module', () {
    test('module const should be Module', () {
      expect(module, isA<Module>());
    });
  });

  group('PreResolve', () {
    test('preResolve const should be PreResolve', () {
      expect(preResolve, isA<PreResolve>());
    });
  });

  group('PostConstruct', () {
    test('should create with default values', () {
      const pc = PostConstruct();

      expect(pc.preResolve, false);
    });

    test('should create with preResolve true', () {
      const pc = PostConstruct(preResolve: true);

      expect(pc.preResolve, true);
    });

    test('postConstruct const should be PostConstruct with defaults', () {
      expect(postConstruct, isA<PostConstruct>());
      expect(postConstruct.preResolve, false);
    });
  });

  group('DisposeMethod', () {
    test('disposeMethod const should be DisposeMethod', () {
      expect(disposeMethod, isA<DisposeMethod>());
    });
  });

  group('Order', () {
    test('should create with position', () {
      const o = Order(10);

      expect(o.position, 10);
    });

    test('order const should be Order with position 0', () {
      expect(order, isA<Order>());
      expect(order.position, 0);
    });
  });

  group('Scope', () {
    test('should create with name', () {
      const scope = Scope('customScope');

      expect(scope.name, 'customScope');
    });
  });

  group('ExternalModule', () {
    test('should create with module type', () {
      const em = ExternalModule(String);

      expect(em.module, String);
      expect(em.scope, isNull);
    });

    test('should create with module type and scope', () {
      const em = ExternalModule(String, scope: 'testScope');

      expect(em.module, String);
      expect(em.scope, 'testScope');
    });
  });

  group('Constants', () {
    test('kEnvironmentsName should be defined', () {
      expect(kEnvironmentsName, '__environments__');
    });

    test('kEnvironmentsFilterName should be defined', () {
      expect(kEnvironmentsFilterName, '__environments__filter__');
    });
  });
}
