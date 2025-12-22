import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/lean_builder/resolvers/lean_dependency_resolver.dart';
import 'package:injectable_generator/lean_builder/resolvers/lean_importable_type_resolver.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/test.dart';
import 'package:test/test.dart';

void main() {
  group('LeanDependencyResolver', () {
    test('resolves simple factory with no dependencies', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class SimpleFactory {}
      ''',
        fileName: 'simple_factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('SimpleFactory')!;

      final result = dependencyResolver.resolve(clazz);

      final type = ImportableType(
        name: 'SimpleFactory',
        import: asset.shortUri.toString(),
      );

      expect(result.type, type);
      expect(result.typeImpl, type);
      expect(result.injectableType, InjectableType.factory);
      expect(result.dependencies, isEmpty);
    });

    test('resolves factory with dependencies', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @injectable
        class FactoryWithDeps {
          FactoryWithDeps(Dependency dep);
        }
      ''',
        fileName: 'factory_with_deps.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('FactoryWithDeps')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.dependencies.length, 1);
      expect(result.dependencies.first.type.name, 'Dependency');
      expect(result.dependencies.first.paramName, 'dep');
      expect(result.dependencies.first.isRequired, true);
    });

    test('resolves factory with nullable dependencies', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @injectable
        class FactoryWithNullableDeps {
          FactoryWithNullableDeps(Dependency? dep);
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.firstWhere(
        (c) => c.name == 'FactoryWithNullableDeps',
      );

      final result = dependencyResolver.resolve(clazz);

      expect(result.dependencies.length, 1);
      expect(result.dependencies.first.type.isNullable, true);
    });

    test('resolves factory with factory params', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @injectable
        class FactoryWithFactoryParams {
          FactoryWithFactoryParams(@factoryParam Dependency dep);
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.firstWhere(
        (c) => c.name == 'FactoryWithFactoryParams',
      );

      final result = dependencyResolver.resolve(clazz);

      expect(result.dependencies.length, 1);
      expect(result.dependencies.first.isFactoryParam, true);
    });

    test('resolves singleton', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Singleton()
        class SimpleSingleton {}
      ''',
        fileName: 'singleton.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.injectableType, InjectableType.singleton);
    });

    test('resolves singleton with signalsReady', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Singleton(signalsReady: true)
        class SingletonWithSignalsReady {}
      ''',
        fileName: 'singleton.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.signalsReady, true);
    });

    test('resolves singleton with dependsOn', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @Singleton(dependsOn: [Dependency])
        class SingletonWithDependsOn {}
      ''',
        fileName: 'singleton.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('SingletonWithDependsOn')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.dependsOn.length, 1);
      expect(result.dependsOn.first.name, 'Dependency');
    });

    test('resolves lazy singleton', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @LazySingleton()
        class SimpleLazySingleton {}
      ''',
        fileName: 'lazy_singleton.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.injectableType, InjectableType.lazySingleton);
    });

    test('resolves named instance with string name', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Named('myName')
        @injectable
        class NamedFactory {}
      ''',
        fileName: 'named_factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.instanceName, 'myName');
    });

    test('resolves named instance from type', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @named
        @injectable
        class NamedFromTypeFactory {}
      ''',
        fileName: 'named_factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.instanceName, 'NamedFromTypeFactory');
    });

    test('resolves factory as abstract type', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        abstract class IFactory {}
        
        @Injectable(as: IFactory)
        class FactoryImpl extends IFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('FactoryImpl')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.type.name, 'IFactory');
      expect(result.typeImpl.name, 'FactoryImpl');
    });

    test('resolves factory with environment', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Environment('dev')
        @injectable
        class DevOnlyFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.environments, contains('dev'));
    });

    test('resolves factory with inline environment', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Injectable(env: ['dev', 'prod'])
        class InlineEnvFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.environments, containsAll(['dev', 'prod']));
    });

    test('resolves factory with scope annotation', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Scope('myScope')
        @injectable
        class ScopedFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.scope, 'myScope');
    });

    test('resolves factory with inline scope', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Injectable(scope: 'myScope')
        class ScopedFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.scope, 'myScope');
    });

    test('resolves factory with order annotation', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Order(5)
        @injectable
        class OrderedFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.orderPosition, 5);
    });

    test('resolves factory with inline order', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Injectable(order: 3)
        class OrderedFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.orderPosition, 3);
    });

    test('resolves factory with named constructor', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class FactoryWithNamedConstructor {
          FactoryWithNamedConstructor._();
          
          @factoryMethod
          FactoryWithNamedConstructor.create() : this._();
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.constructorName, 'create');
    });

    test('resolves factory with static factory method', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class FactoryWithStaticMethod {
          FactoryWithStaticMethod._();
          
          @factoryMethod
          static FactoryWithStaticMethod create() => FactoryWithStaticMethod._();
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.constructorName, 'create');
    });

    test('resolves async factory', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class AsyncFactory {
          AsyncFactory._();
          
          @factoryMethod
          static Future<AsyncFactory> create() async => AsyncFactory._();
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.isAsync, true);
    });

    test('resolves factory with preResolve annotation', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @preResolve
        @injectable
        class PreResolveFactory {
          PreResolveFactory._();
          
          @factoryMethod
          static Future<PreResolveFactory> create() async => PreResolveFactory._();
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.preResolve, true);
    });

    test('resolves factory with cache', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Injectable(cache: true)
        class CachedFactory {}
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.cache, true);
    });

    test('resolves const factory', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class ConstFactory {
          const ConstFactory();
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.canBeConst, true);
    });

    test('resolves factory with dispose method', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @LazySingleton()
        class FactoryWithDispose {
          @disposeMethod
          void dispose() {}
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.disposeFunction, isNotNull);
      expect(result.disposeFunction!.isInstance, true);
      expect(result.disposeFunction!.name, 'dispose');
    });

    test('resolves factory with post construct', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class FactoryWithPostConstruct {
          @postConstruct
          void init() {}
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.postConstruct, 'init');
      expect(result.postConstructReturnsSelf, false);
    });

    test('resolves factory with post construct that returns self', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class FactoryWithPostConstruct {
          @postConstruct
          FactoryWithPostConstruct init() => this;
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;

      final result = dependencyResolver.resolve(clazz);

      expect(result.postConstruct, 'init');
      expect(result.postConstructReturnsSelf, true);
    });

    test('resolves module member', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Service {}
        
        @module
        abstract class AppModule {
          Service get service;
        }
      ''',
        fileName: 'module.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final moduleClass = library.classes.firstWhere(
        (c) => c.name == 'AppModule',
      );
      final getter = moduleClass.accessors.first;

      final result = dependencyResolver.resolveModuleMember(
        moduleClass,
        getter,
      );

      expect(result.type.name, 'Service');
      expect(result.moduleConfig, isNotNull);
      expect(result.moduleConfig!.isAbstract, true);
      expect(result.moduleConfig!.type.name, 'AppModule');
    });

    test('resolves factory with ignored parameter', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @injectable
        class FactoryWithIgnoredParam {
          FactoryWithIgnoredParam(Dependency dep, {@ignoreParam String? ignored});
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('FactoryWithIgnoredParam')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.dependencies.length, 1);
      expect(result.dependencies.first.type.name, 'Dependency');
    });

    test('resolves factory with named dependency', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @injectable
        class FactoryWithNamedDep {
          FactoryWithNamedDep(@Named('special') Dependency dep);
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('FactoryWithNamedDep')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.dependencies.length, 1);
      expect(result.dependencies.first.instanceName, 'special');
    });

    test('resolves factory with positional and named parameters', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dep1 {}
        class Dep2 {}
        
        @injectable
        class FactoryWithMixedParams {
          FactoryWithMixedParams(Dep1 first, {required Dep2 second});
        }
      ''',
        fileName: 'factory.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('FactoryWithMixedParams')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.dependencies.length, 2);
      expect(result.dependencies[0].isPositional, true);
      expect(result.dependencies[1].isPositional, false);
      expect(result.dependencies[1].isRequired, true);
    });

    // Error condition tests
    test('throws error for non-class return type in module member', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @module
        abstract class AppModule {
          String get invalidReturn;
        }
      ''',
        fileName: 'module.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final moduleClass = library.getClass('AppModule')!;
      final getter = moduleClass.accessors.first;

      expect(
        () => dependencyResolver.resolveModuleMember(moduleClass, getter),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for abstract module method with parameters', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Service {}
        
        @module
        abstract class AppModule {
          Service getService(String param);
        }
      ''',
        fileName: 'module.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final moduleClass = library.getClass('AppModule')!;
      final method = moduleClass.methods.first;

      expect(
        () => dependencyResolver.resolveModuleMember(moduleClass, method),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for invalid abstract type', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class NotAnInterface {}
        
        @Injectable(as: NotAnInterface)
        class MyService {}
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('MyService')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for cache on non-factory type', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Singleton(cache: true)
        class InvalidCached {}
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('InvalidCached')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for factory dispose method', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class FactoryWithDispose {
          @disposeMethod
          void dispose() {}
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('FactoryWithDispose')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for dispose method with required parameters', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @LazySingleton()
        class ServiceWithBadDispose {
          @disposeMethod
          void dispose(String required) {}
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('ServiceWithBadDispose')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for non-factory with factory params', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @Singleton()
        class InvalidSingleton {
          InvalidSingleton(@factoryParam Dependency dep);
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('InvalidSingleton')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for more than 2 factory params', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class TooManyParams {
          TooManyParams(
            @factoryParam int a,
            @factoryParam int b,
            @factoryParam int c,
          );
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('TooManyParams')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for preResolve with factory params', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class InvalidPreResolve {
          InvalidPreResolve(int param);
          
          @preResolve
          @factoryMethod
          static Future<InvalidPreResolve> create(@factoryParam int param) async {
            return InvalidPreResolve(param);
          }
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('InvalidPreResolve')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for static post construct method', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class InvalidPostConstruct {
          @postConstruct
          static void init() {}
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('InvalidPostConstruct')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for private post construct method', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class InvalidPostConstruct {
          @postConstruct
          void _init() {}
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('InvalidPostConstruct')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for post construct with required parameters', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class InvalidPostConstruct {
          @postConstruct
          void init(String required) {}
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('InvalidPostConstruct')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('throws error for ignored param that is not optional', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Dependency {}
        
        @injectable
        class InvalidIgnored {
          InvalidIgnored(@ignoreParam Dependency dep);
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('InvalidIgnored')!;

      expect(
        () => dependencyResolver.resolve(clazz),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    // Edge case tests
    test('resolves module method returning Future', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        class Service {}
        
        @module
        abstract class AppModule {
          Future<Service> getService() async => Service();
        }
      ''',
        fileName: 'module.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final moduleClass = library.getClass('AppModule')!;
      final method = moduleClass.methods.first;

      final result = dependencyResolver.resolveModuleMember(
        moduleClass,
        method,
      );

      expect(result.type.name, 'Service');
      expect(result.moduleConfig, isNotNull);
      expect(result.moduleConfig!.isAbstract, false);
    });

    test('resolves external dispose function', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        void disposeService(ServiceWithExternalDispose service) {}
        
        @LazySingleton(dispose: disposeService)
        class ServiceWithExternalDispose {}
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('ServiceWithExternalDispose')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.disposeFunction, isNotNull);
      expect(result.disposeFunction!.isInstance, false);
      expect(result.disposeFunction!.name, 'disposeService');
    });

    test('resolves async post construct with preResolve', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @injectable
        class AsyncPostConstruct {
          @PostConstruct(preResolve: true)
          Future<void> init() async {}
        }
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('AsyncPostConstruct')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.postConstruct, 'init');
      expect(result.isAsync, true);
      expect(result.preResolve, true);
    });

    test('resolves named instance with empty string uses class name', () async {
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        
        @Named('')
        @injectable
        class MyService {}
      ''',
        fileName: 'service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        includePackages: {'injectable'},
      );
      final resolver = LeanTypeResolverImpl(buildStep.resolver);
      final dependencyResolver = LeanDependencyResolver(resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.getClass('MyService')!;

      final result = dependencyResolver.resolve(clazz);

      expect(result.instanceName, 'MyService');
    });
  });
}
