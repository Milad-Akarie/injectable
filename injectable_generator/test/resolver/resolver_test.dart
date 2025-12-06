import 'package:analyzer/dart/element/element.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/resolvers/dependency_resolver.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'utils.dart';

class MockTypeResolver extends ImportableTypeResolverImpl {
  MockTypeResolver() : super([]);

  @override
  Set<String> resolveImports(Element? element) {
    return {'source.dart'};
  }
}

void main() async {
  ResolvedInput? resolvedInput;
  DependencyResolver? dependencyResolver;
  setUpAll(() async {
    resolvedInput = await resolveInput('test/resolver/samples/source.dart');
  });
  setUp(() {
    dependencyResolver = DependencyResolver(MockTypeResolver());
  });
  group('Dependency Resolver', () {
    test('Factory without annotation', () {
      var factoryWithoutAnnotationType = resolvedInput!.library.findType(
        'FactoryWithoutAnnotation',
      )!;

      final type = ImportableType(
        name: 'FactoryWithoutAnnotation',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithoutAnnotationType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            constructorName: 'valid',
          ),
        ),
      );
    });

    test('Simple Factory no dependencies', () {
      var simpleFactoryType = resolvedInput!.library.findType('SimpleFactory')!;

      final type = ImportableType(name: 'SimpleFactory', import: 'source.dart');
      expect(
        dependencyResolver!.resolve(simpleFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
          ),
        ),
      );
    });

    test('Factory with nullable dependencies', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'FactoryWithNullableDeps',
      )!;
      final type = ImportableType(
        name: 'FactoryWithNullableDeps',
        import: 'source.dart',
      );

      final dependencyType = ImportableType(
        name: 'SimpleFactory',
        import: 'source.dart',
        isNullable: true,
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: dependencyType,
                paramName: 'simpleFactory',
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with dependencies', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'FactoryWithDeps',
      )!;
      final type = ImportableType(
        name: 'FactoryWithDeps',
        import: 'source.dart',
      );

      final dependencyType = ImportableType(
        name: 'SimpleFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: dependencyType,
                paramName: 'simpleFactory',
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with nullable factoryParams', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'FactoryWithNullableFactoryParams',
      )!;
      final type = ImportableType(
        name: 'FactoryWithNullableFactoryParams',
        import: 'source.dart',
      );

      final dependencyType = ImportableType(
        name: 'SimpleFactory',
        import: 'source.dart',
        isNullable: true,
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: dependencyType,
                paramName: 'simpleFactory',
                isFactoryParam: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with @ignoreParam', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'FactoryWithIgnoredParam',
      )!;
      final type = ImportableType(
        name: 'FactoryWithIgnoredParam',
        import: 'source.dart',
      );

      final dependencyType = ImportableType(
        name: 'SimpleFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: dependencyType,
                paramName: 'simpleFactory',
                isPositional: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with factoryParams', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'FactoryWithFactoryParams',
      )!;
      final type = ImportableType(
        name: 'FactoryWithFactoryParams',
        import: 'source.dart',
      );

      final dependencyType = ImportableType(
        name: 'SimpleFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: dependencyType,
                paramName: 'simpleFactory',
                isFactoryParam: true,
                isPositional: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with typeDef NamedRecord factoryParam', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'NamedRecordFactory',
      )!;
      final type = ImportableType(
        name: 'NamedRecordFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'NamedRecord',
                  import: 'source.dart',
                ),
                paramName: 'record',
                isFactoryParam: true,
                isPositional: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with Inline NamedRecord factoryParam', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'InlineNamedRecord',
      )!;
      final type = ImportableType(
        name: 'InlineNamedRecord',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType.record(
                  name: '',
                  import: 'source.dart',
                  typeArguments: [
                    ImportableType(
                      name: 'SimpleFactory',
                      import: 'source.dart',
                      nameInRecord: 'x',
                    ),
                    ImportableType(
                      name: 'int',
                      import: 'source.dart',
                      nameInRecord: 'y',
                    ),
                  ],
                ),
                paramName: 'record',
                isFactoryParam: true,
                isPositional: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with typeDef PositionalRecord factoryParam', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'PositionalRecordFactory',
      )!;
      final type = ImportableType(
        name: 'PositionalRecordFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'PositionalRecord',
                  import: 'source.dart',
                ),
                paramName: 'record',
                isFactoryParam: true,
                isPositional: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with Inline PositionalRecord factoryParam', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'InlinePositionalRecord',
      )!;
      final type = ImportableType(
        name: 'InlinePositionalRecord',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType.record(
                  name: '',
                  import: 'source.dart',
                  typeArguments: [
                    ImportableType(
                      name: 'SimpleFactory',
                      import: 'source.dart',
                    ),
                    ImportableType(name: 'int', import: 'source.dart'),
                  ],
                ),
                paramName: 'record',
                isFactoryParam: true,
                isPositional: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Simple Factory as abstract no dependencies', () {
      var factoryAsAbstract = resolvedInput!.library.findType(
        'FactoryAsAbstract',
      )!;

      final type = ImportableType(name: 'IFactory', import: 'source.dart');

      final typeImpl = ImportableType(
        name: 'FactoryAsAbstract',
        import: 'source.dart',
      );

      expect(
        dependencyResolver!.resolve(factoryAsAbstract),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: typeImpl,
            injectableType: InjectableType.factory,
          ),
        ),
      );
    });

    test('factory with named static factory constructor', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'FactoryWithFactoryStaticConstructor',
      )!;
      final type = ImportableType(
        name: 'FactoryWithFactoryStaticConstructor',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [],
          isAsync: false,
          constructorName: 'namedFactory',
        ),
      );
    });

    test('factory with named constructor', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'FactoryWithNamedConstructor',
      )!;
      final type = ImportableType(
        name: 'FactoryWithNamedConstructor',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [],
          isAsync: false,
          constructorName: 'namedFactory',
        ),
      );
    });

    test('Async factory with nullable dependencies', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'AsyncFactoryWithNullableDeps',
      )!;
      final type = ImportableType(
        name: 'AsyncFactoryWithNullableDeps',
        import: 'source.dart',
      );

      final dependencyType = ImportableType(
        name: 'SimpleFactory',
        import: 'source.dart',
        isNullable: true,
      );
      expect(
        dependencyResolver!.resolve(factoryWithDeps),
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: dependencyType,
              paramName: 'simpleFactory',
              isFactoryParam: true,
              isRequired: true,
            ),
          ],
          isAsync: true,
          constructorName: 'create',
        ),
      );
    });

    test('Async factory with non nullable dependencies', () {
      final factoryWithDeps = resolvedInput!.library.findType(
        'AsyncFactoryWithNonNullableDeps',
      )!;
      final errorMessage = 'Async factory params must be nullable';
      InvalidGenerationSourceError? resultError;
      try {
        dependencyResolver!.resolve(factoryWithDeps);
      } catch (error) {
        resultError = error as InvalidGenerationSourceError;
      }
      expect(resultError?.message, errorMessage);
    });

    test('Simple Factory with inline order', () {
      var simpleFactoryType = resolvedInput!.library.findType(
        'FactoryWithInlineOrder',
      )!;
      final type = ImportableType(
        name: 'FactoryWithInlineOrder',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(simpleFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            orderPosition: 1,
            canBeConst: true,
          ),
        ),
      );
    });

    test('Simple Factory with annotation order', () {
      var simpleFactoryType = resolvedInput!.library.findType(
        'FactoryWithAnnotationOrder',
      )!;
      final type = ImportableType(
        name: 'FactoryWithAnnotationOrder',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(simpleFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            orderPosition: 1,
            canBeConst: true,
          ),
        ),
      );
    });

    test('Simple Factory with inline scope', () {
      var simpleFactoryType = resolvedInput!.library.findType(
        'FactoryWithInlineScope',
      )!;
      final type = ImportableType(
        name: 'FactoryWithInlineScope',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(simpleFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            scope: 'scope',
            canBeConst: true,
          ),
        ),
      );
    });

    test('Simple Factory with annotation scope', () {
      var simpleFactoryType = resolvedInput!.library.findType(
        'FactoryWithAnnotationScope',
      )!;
      final type = ImportableType(
        name: 'FactoryWithAnnotationScope',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(simpleFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            scope: 'scope',
            canBeConst: true,
          ),
        ),
      );
    });

    test('Const injectable with no deps can generate const instances', () {
      var simpleFactoryType = resolvedInput!.library.findType('ConstService')!;
      final type = ImportableType(name: 'ConstService', import: 'source.dart');
      expect(
        dependencyResolver!.resolve(simpleFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            canBeConst: true,
          ),
        ),
      );
    });

    test('Const injectable with deps can not generate const instances', () {
      var simpleFactoryType = resolvedInput!.library.findType(
        'ConstServiceWithDeps',
      )!;
      final type = ImportableType(
        name: 'ConstServiceWithDeps',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(simpleFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'SimpleFactory',
                  import: 'source.dart',
                ),
                paramName: 'simpleFactory',
                isRequired: true,
              ),
            ],
            injectableType: InjectableType.factory,
            canBeConst: false,
          ),
        ),
      );
    });

    test('Simple Singleton', () {
      var simpleSingletonType = resolvedInput!.library.findType(
        'SimpleSingleton',
      )!;
      final type = ImportableType(
        name: 'SimpleSingleton',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(simpleSingletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.singleton,
            canBeConst: false,
          ),
        ),
      );
    });

    test('Singleton with signalsReady', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithSignalsReady',
      )!;
      final type = ImportableType(
        name: 'SingletonWithSignalsReady',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(singletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.singleton,
            signalsReady: true,
            canBeConst: false,
          ),
        ),
      );
    });

    test('Singleton with dependsOn', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithDependsOn',
      )!;
      final type = ImportableType(
        name: 'SingletonWithDependsOn',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(singletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.singleton,
            dependsOn: [
              ImportableType(name: 'SimpleFactory', import: 'source.dart'),
            ],
            canBeConst: false,
          ),
        ),
      );
    });

    test('Singleton with signalsReady and dependsOn', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithSignalsReadyAndDependsOn',
      )!;
      final type = ImportableType(
        name: 'SingletonWithSignalsReadyAndDependsOn',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(singletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.singleton,
            signalsReady: true,
            dependsOn: [
              ImportableType(name: 'SimpleFactory', import: 'source.dart'),
              ImportableType(name: 'SimpleSingleton', import: 'source.dart'),
            ],
          ),
        ),
      );
    });

    test('Simple LazySingleton', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'SimpleLazySingleton',
      )!;
      final type = ImportableType(
        name: 'SimpleLazySingleton',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(lazySingletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.lazySingleton,
            canBeConst: false,
          ),
        ),
      );
    });

    test('LazySingleton with dependencies', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'LazySingletonWithDeps',
      )!;
      final type = ImportableType(
        name: 'LazySingletonWithDeps',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(lazySingletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.lazySingleton,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'SimpleFactory',
                  import: 'source.dart',
                ),
                paramName: 'simpleFactory',
                isRequired: true,
              ),
            ],
            canBeConst: false,
          ),
        ),
      );
    });

    test('Named factory with string name', () {
      var namedFactoryType = resolvedInput!.library.findType('NamedFactory')!;
      final type = ImportableType(name: 'NamedFactory', import: 'source.dart');
      expect(
        dependencyResolver!.resolve(namedFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            instanceName: 'myName',
            canBeConst: false,
          ),
        ),
      );
    });

    test('Named factory from type', () {
      var namedFactoryType = resolvedInput!.library.findType(
        'NamedFromTypeFactory',
      )!;
      final type = ImportableType(
        name: 'NamedFromTypeFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(namedFactoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            instanceName: 'NamedFromTypeFactory',
          ),
        ),
      );
    });

    test('Factory with single environment', () {
      var factoryType = resolvedInput!.library.findType('DevOnlyFactory')!;
      final type = ImportableType(
        name: 'DevOnlyFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            environments: ['dev'],
            canBeConst: false,
          ),
        ),
      );
    });

    test('Factory with multiple environments', () {
      var factoryType = resolvedInput!.library.findType('DevAndTestFactory')!;
      final type = ImportableType(
        name: 'DevAndTestFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            environments: ['dev', 'test'],
            canBeConst: false,
          ),
        ),
      );
    });

    test('Factory with inline environments', () {
      var factoryType = resolvedInput!.library.findType('InlineEnvFactory')!;
      final type = ImportableType(
        name: 'InlineEnvFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            environments: ['dev', 'prod'],
            canBeConst: false,
          ),
        ),
      );
    });

    test('PreResolve factory', () {
      var factoryType = resolvedInput!.library.findType('PreResolveFactory')!;
      final type = ImportableType(
        name: 'PreResolveFactory',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          preResolve: true,
          isAsync: true,
          constructorName: 'create',
        ),
      );
    });

    test('Factory method with preResolve in annotation', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryMethodWithPreResolve',
      )!;
      final type = ImportableType(
        name: 'FactoryMethodWithPreResolve',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          preResolve: true,
          isAsync: true,
          constructorName: 'create',
        ),
      );
    });

    test('Factory with PostConstruct', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithPostConstruct',
      )!;
      final type = ImportableType(
        name: 'FactoryWithPostConstruct',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          postConstruct: 'init',
          canBeConst: false,
        ),
      );
    });

    test('Factory with async PostConstruct', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithAsyncPostConstruct',
      )!;
      final type = ImportableType(
        name: 'FactoryWithAsyncPostConstruct',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          postConstruct: 'init',
          isAsync: true,
          canBeConst: false,
        ),
      );
    });

    test('Factory with PostConstruct that returns self', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithPostConstructReturnsSelf',
      )!;
      final type = ImportableType(
        name: 'FactoryWithPostConstructReturnsSelf',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            postConstruct: 'init',
            postConstructReturnsSelf: true,
            canBeConst: false,
          ),
        ),
      );
    });

    test(
      'Factory with async PostConstruct that returns self with preResolve',
      () {
        var factoryType = resolvedInput!.library.findType(
          'FactoryWithAsyncPostConstructReturnsSelf',
        )!;
        final type = ImportableType(
          name: 'FactoryWithAsyncPostConstructReturnsSelf',
          import: 'source.dart',
        );
        expect(
          dependencyResolver!.resolve(factoryType),
          equals(
            DependencyConfig(
              type: type,
              typeImpl: type,
              injectableType: InjectableType.factory,
              postConstruct: 'init',
              postConstructReturnsSelf: true,
              isAsync: true,
              preResolve: true,
              canBeConst: false,
            ),
          ),
        );
      },
    );

    test('Cached factory', () {
      var factoryType = resolvedInput!.library.findType('CachedFactory')!;
      final type = ImportableType(name: 'CachedFactory', import: 'source.dart');
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            cache: true,
            canBeConst: true,
          ),
        ),
      );
    });

    test('Factory with two factory params', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithTwoFactoryParams',
      )!;
      final type = ImportableType(
        name: 'FactoryWithTwoFactoryParams',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'SimpleFactory',
                  import: 'source.dart',
                ),
                paramName: 'simpleFactory',
                isFactoryParam: true,
                isPositional: true,
                isRequired: true,
              ),
              InjectedDependency(
                type: ImportableType(name: 'int', import: 'source.dart'),
                paramName: 'count',
                isFactoryParam: true,
                isPositional: true,
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with named dependency', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNamedDependency',
      )!;
      final type = ImportableType(
        name: 'FactoryWithNamedDependency',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'SimpleFactory',
                  import: 'source.dart',
                ),
                paramName: 'simpleFactory',
                instanceName: 'myName',
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with named type dependency', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNamedTypeDependency',
      )!;
      final type = ImportableType(
        name: 'FactoryWithNamedTypeDependency',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'SimpleFactory',
                  import: 'source.dart',
                ),
                paramName: 'simpleFactory',
                instanceName: 'SimpleFactory',
                isRequired: true,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with optional positional params', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithOptionalParams',
      )!;
      final type = ImportableType(
        name: 'FactoryWithOptionalParams',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'SimpleFactory',
                  import: 'source.dart',
                ),
                paramName: 'simpleFactory',
                isPositional: true,
                isRequired: true,
              ),
              InjectedDependency(
                type: ImportableType(
                  name: 'int',
                  import: 'source.dart',
                  isNullable: true,
                ),
                paramName: 'optional',
                isPositional: true,
                isRequired: false,
              ),
            ],
          ),
        ),
      );
    });

    test('Factory with optional named params', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithOptionalNamedParams',
      )!;
      final type = ImportableType(
        name: 'FactoryWithOptionalNamedParams',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(factoryType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(
                  name: 'SimpleFactory',
                  import: 'source.dart',
                ),
                paramName: 'simpleFactory',
                isPositional: true,
                isRequired: true,
              ),
              InjectedDependency(
                type: ImportableType(
                  name: 'int',
                  import: 'source.dart',
                  isNullable: true,
                ),
                paramName: 'optional',
                isPositional: false,
                isRequired: false,
              ),
            ],
          ),
        ),
      );
    });

    test('LazySingleton with dispose method', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'LazySingletonWithDisposeMethod',
      )!;
      final type = ImportableType(
        name: 'LazySingletonWithDisposeMethod',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(lazySingletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.lazySingleton,
            disposeFunction: DisposeFunctionConfig(
              isInstance: true,
              name: 'dispose',
            ),
            canBeConst: true,
          ),
        ),
      );
    });

    test('Singleton with dispose method', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithDisposeMethod',
      )!;
      final type = ImportableType(
        name: 'SingletonWithDisposeMethod',
        import: 'source.dart',
      );
      expect(
        dependencyResolver!.resolve(singletonType),
        equals(
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.singleton,
            disposeFunction: DisposeFunctionConfig(
              isInstance: true,
              name: 'dispose',
            ),
            canBeConst: true,
          ),
        ),
      );
    });

    test('Factory with dependencies and default values', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithOptionalNamedParams',
      )!;
      final type = ImportableType(
        name: 'FactoryWithOptionalNamedParams',
        import: 'source.dart',
      );
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.type, equals(type));
      expect(result.dependencies.length, equals(2));
      expect(result.dependencies[0].isRequired, isTrue);
      expect(result.dependencies[1].isRequired, isFalse);
    });

    test('Factory with multiple environments should merge them', () {
      var factoryType = resolvedInput!.library.findType('DevAndTestFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.environments, containsAll(['dev', 'test']));
      expect(result.environments.length, equals(2));
    });

    test('Singleton with both signalsReady and dependsOn should have both', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithSignalsReadyAndDependsOn',
      )!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.signalsReady, isTrue);
      expect(result.dependsOn.length, equals(2));
    });

    test('Factory with named dependency should preserve instance name', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNamedDependency',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.first.instanceName, equals('myName'));
    });

    test('Factory with named type dependency should use type name', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNamedTypeDependency',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.first.instanceName, equals('SimpleFactory'));
    });

    test('PreResolve factory should have isAsync true', () {
      var factoryType = resolvedInput!.library.findType('PreResolveFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.preResolve, isTrue);
      expect(result.isAsync, isTrue);
    });

    test('FactoryMethod with preResolve in annotation', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryMethodWithPreResolve',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.preResolve, isTrue);
      expect(result.isAsync, isTrue);
    });

    test('Named factory from type should use class name', () {
      var factoryType = resolvedInput!.library.findType(
        'NamedFromTypeFactory',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.instanceName, equals('NamedFromTypeFactory'));
    });

    test('Factory with inline scope should have scope set', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithInlineScope',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.scope, equals('scope'));
    });

    test('Factory with annotation scope should have scope set', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithAnnotationScope',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.scope, equals('scope'));
    });

    test('Factory with inline order should have order set', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithInlineOrder',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.orderPosition, equals(1));
    });

    test('Factory with annotation order should have order set', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithAnnotationOrder',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.orderPosition, equals(1));
    });

    test('Cached factory should have cache flag set', () {
      var factoryType = resolvedInput!.library.findType('CachedFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.cache, isTrue);
    });

    test('Factory with two factory params should have both params', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithTwoFactoryParams',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(2));
      expect(result.dependencies.every((d) => d.isFactoryParam), isTrue);
    });

    test('Factory with ignored param should skip ignored param', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithIgnoredParam',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(1));
      expect(result.dependencies.first.paramName, equals('simpleFactory'));
    });

    test('LazySingleton with dependencies should preserve dependencies', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'LazySingletonWithDeps',
      )!;
      final result = dependencyResolver!.resolve(lazySingletonType);
      expect(result.injectableType, equals(InjectableType.lazySingleton));
      expect(result.dependencies.length, equals(1));
    });

    test('Singleton with signalsReady should have flag set', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithSignalsReady',
      )!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.signalsReady, isTrue);
    });

    test('Singleton with dependsOn should have dependencies', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithDependsOn',
      )!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.dependsOn.length, equals(1));
      expect(result.dependsOn.first.name, equals('SimpleFactory'));
    });

    test('Factory as abstract should have different type and typeImpl', () {
      var factoryType = resolvedInput!.library.findType('FactoryAsAbstract')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.type.name, equals('IFactory'));
      expect(result.typeImpl.name, equals('FactoryAsAbstract'));
    });

    test('Factory with nullable dependencies should preserve nullability', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNullableDeps',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.first.type.isNullable, isTrue);
    });

    test(
      'Factory with nullable factory params should preserve nullability',
      () {
        var factoryType = resolvedInput!.library.findType(
          'FactoryWithNullableFactoryParams',
        )!;
        final result = dependencyResolver!.resolve(factoryType);
        expect(result.dependencies.first.isFactoryParam, isTrue);
        expect(result.dependencies.first.type.isNullable, isTrue);
      },
    );

    test('Named record factory should resolve correctly', () {
      var factoryType = resolvedInput!.library.findType('NamedRecordFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.first.isFactoryParam, isTrue);
      expect(result.dependencies.first.type.name, equals('NamedRecord'));
    });

    test('Positional record factory should resolve correctly', () {
      var factoryType = resolvedInput!.library.findType(
        'PositionalRecordFactory',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.first.isFactoryParam, isTrue);
      expect(result.dependencies.first.type.name, equals('PositionalRecord'));
    });

    test('Inline named record should resolve with empty name', () {
      var factoryType = resolvedInput!.library.findType('InlineNamedRecord')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.first.type.name, isEmpty);
      expect(result.dependencies.first.type.isRecordType, isTrue);
    });

    test('Inline positional record should resolve with empty name', () {
      var factoryType = resolvedInput!.library.findType(
        'InlinePositionalRecord',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.first.type.name, isEmpty);
      expect(result.dependencies.first.type.isRecordType, isTrue);
    });

    test('Factory with named constructor should set constructorName', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNamedConstructor',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.constructorName, equals('namedFactory'));
    });

    test(
      'Factory with static factory constructor should set constructorName',
      () {
        var factoryType = resolvedInput!.library.findType(
          'FactoryWithFactoryStaticConstructor',
        )!;
        final result = dependencyResolver!.resolve(factoryType);
        expect(result.constructorName, equals('namedFactory'));
      },
    );

    test('Simple factory should have default order of 0', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.orderPosition, equals(0));
    });

    test('Const service with no deps should be canBeConst', () {
      var serviceType = resolvedInput!.library.findType('ConstService')!;
      final result = dependencyResolver!.resolve(serviceType);
      expect(result.canBeConst, isTrue);
    });

    test('Const service with deps should not be canBeConst', () {
      var serviceType = resolvedInput!.library.findType(
        'ConstServiceWithDeps',
      )!;
      final result = dependencyResolver!.resolve(serviceType);
      expect(result.canBeConst, isFalse);
    });

    test(
      'Factory with optional positional params should mark optional correctly',
      () {
        var factoryType = resolvedInput!.library.findType(
          'FactoryWithOptionalParams',
        )!;
        final result = dependencyResolver!.resolve(factoryType);
        expect(result.dependencies[0].isRequired, isTrue);
        expect(result.dependencies[1].isRequired, isFalse);
        expect(result.dependencies[1].isPositional, isTrue);
      },
    );

    test('Inline env factory should have both environments', () {
      var factoryType = resolvedInput!.library.findType('InlineEnvFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.environments, containsAll(['dev', 'prod']));
    });

    test('DevOnly factory should have single environment', () {
      var factoryType = resolvedInput!.library.findType('DevOnlyFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.environments, equals(['dev']));
    });

    test(
      'Factory without annotation should pick first available constructor',
      () {
        var factoryType = resolvedInput!.library.findType(
          'FactoryWithoutAnnotation',
        )!;
        final result = dependencyResolver!.resolve(factoryType);
        expect(result.constructorName, equals('valid'));
      },
    );

    test('Async factory with nullable deps should be async', () {
      var factoryType = resolvedInput!.library.findType(
        'AsyncFactoryWithNullableDeps',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.isAsync, isTrue);
      expect(result.dependencies.first.type.isNullable, isTrue);
    });

    test('PostConstruct method should be detected', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithPostConstruct',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.postConstruct, equals('init'));
      expect(result.postConstructReturnsSelf, isFalse);
    });

    test('Async PostConstruct should make factory async', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithAsyncPostConstruct',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.postConstruct, equals('init'));
      expect(result.isAsync, isTrue);
    });

    test('PostConstruct returning self should set flag', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithPostConstructReturnsSelf',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.postConstruct, equals('init'));
      expect(result.postConstructReturnsSelf, isTrue);
    });

    test('Async PostConstruct returning self with preResolve', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithAsyncPostConstructReturnsSelf',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.postConstruct, equals('init'));
      expect(result.postConstructReturnsSelf, isTrue);
      expect(result.isAsync, isTrue);
      expect(result.preResolve, isTrue);
    });

    test('Simple singleton should not be const', () {
      var singletonType = resolvedInput!.library.findType('SimpleSingleton')!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.canBeConst, isFalse);
      expect(result.injectableType, equals(InjectableType.singleton));
    });

    test('Simple lazy singleton should not be const', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'SimpleLazySingleton',
      )!;
      final result = dependencyResolver!.resolve(lazySingletonType);
      expect(result.canBeConst, isFalse);
      expect(result.injectableType, equals(InjectableType.lazySingleton));
    });

    test('LazySingleton with dispose should have dispose config', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'LazySingletonWithDisposeMethod',
      )!;
      final result = dependencyResolver!.resolve(lazySingletonType);
      expect(result.disposeFunction, isNotNull);
      expect(result.disposeFunction!.isInstance, isTrue);
      expect(result.disposeFunction!.name, equals('dispose'));
    });

    test('Named factory should have correct instance name', () {
      var namedFactoryType = resolvedInput!.library.findType('NamedFactory')!;
      final result = dependencyResolver!.resolve(namedFactoryType);
      expect(result.instanceName, equals('myName'));
    });

    test('Factory with generic list dependencies', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithGenericDeps',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(1));
      expect(result.dependencies.first.type.name, equals('List'));
      expect(result.dependencies.first.type.typeArguments.length, equals(1));
      expect(
        result.dependencies.first.type.typeArguments.first.name,
        equals('SimpleFactory'),
      );
    });

    test('Factory with map dependencies', () {
      var factoryType = resolvedInput!.library.findType('FactoryWithMapDeps')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(1));
      expect(result.dependencies.first.type.name, equals('Map'));
      expect(result.dependencies.first.type.typeArguments.length, equals(2));
    });

    test('Factory with required named params', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithRequiredNamedParams',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(1));
      expect(result.dependencies.first.isRequired, isTrue);
      expect(result.dependencies.first.isPositional, isFalse);
    });

    test('Factory with mixed parameters', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithMixedParams',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(4));
      expect(result.dependencies[0].isPositional, isTrue);
      expect(result.dependencies[0].paramName, equals('first'));
      expect(result.dependencies[1].isFactoryParam, isTrue);
      expect(result.dependencies[1].paramName, equals('count'));
      expect(result.dependencies[2].isRequired, isFalse);
      expect(result.dependencies[2].isPositional, isFalse);
      expect(result.dependencies[2].paramName, equals('optional'));
      expect(result.dependencies[3].isRequired, isTrue);
      expect(result.dependencies[3].isPositional, isFalse);
      expect(result.dependencies[3].paramName, equals('singleton'));
    });

    test('Multiple interfaces implementation', () {
      var factoryType = resolvedInput!.library.findType('MultipleInterfaces')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.type.name, equals('IFactory'));
      expect(result.typeImpl.name, equals('MultipleInterfaces'));
    });

    test('LazySingleton with async dispose', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'LazySingletonWithAsyncDispose',
      )!;
      final result = dependencyResolver!.resolve(lazySingletonType);
      expect(result.disposeFunction, isNotNull);
      expect(result.disposeFunction!.isInstance, isTrue);
      expect(result.disposeFunction!.name, equals('dispose'));
    });

    test('Factory with function parameter', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithFunctionParam',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(1));
      // Function types defined with typedef should have the typedef name
      expect(result.dependencies.first.type.name, equals('VoidCallback'));
    });

    test('Factory with complex generic map', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithComplexGeneric',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(1));
      expect(result.dependencies.first.type.name, equals('Map'));
      expect(result.dependencies.first.type.typeArguments.length, equals(2));
      expect(
        result.dependencies.first.type.typeArguments[1].name,
        equals('List'),
      );
    });

    test('Factory with default value parameter', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithDefaultValue',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(2));
      expect(result.dependencies[0].isRequired, isTrue);
      expect(result.dependencies[1].isRequired, isFalse);
    });

    test('Singleton with multiple dependsOn', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithMultipleDependsOn',
      )!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.dependsOn.length, equals(3));
      expect(
        result.dependsOn.map((e) => e.name),
        containsAll([
          'SimpleFactory',
          'SimpleSingleton',
          'SimpleLazySingleton',
        ]),
      );
    });

    test('Factory with empty environment list', () {
      var factoryType = resolvedInput!.library.findType('FactoryWithEmptyEnv')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.environments, isEmpty);
    });

    test('Factory with multiple named parameters', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithMultipleNamedParams',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(3));
      expect(result.dependencies.every((d) => !d.isPositional), isTrue);
      expect(result.dependencies.every((d) => !d.isRequired), isTrue);
    });

    test('Factory with both positional and named params', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithBothPositionalAndNamed',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(2));
      expect(result.dependencies[0].isPositional, isTrue);
      expect(result.dependencies[1].isPositional, isFalse);
    });

    test('Factory with nullable generic', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNullableGeneric',
      )!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.dependencies.length, equals(1));
      expect(result.dependencies.first.type.isNullable, isTrue);
      expect(result.dependencies.first.type.name, equals('List'));
    });

    test('Singleton without signalsReady should have null signalsReady', () {
      var singletonType = resolvedInput!.library.findType('SimpleSingleton')!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.signalsReady, isNull);
    });

    test('Factory without environments should have empty list', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.environments, isEmpty);
    });

    test('Factory without scope should have null scope', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.scope, isNull);
    });

    test('Factory without cache should have false cache', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.cache, isFalse);
    });

    test('Factory without postConstruct should have null postConstruct', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.postConstruct, isNull);
    });

    test('Factory without instance name should have null instanceName', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.instanceName, isNull);
    });

    test('Factory without preResolve should have false preResolve', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.preResolve, isFalse);
    });

    test('Factory without dispose should have null disposeFunction', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.disposeFunction, isNull);
    });

    test('Singleton with dispose should have async dispose function', () {
      var singletonType = resolvedInput!.library.findType(
        'SingletonWithDisposeMethod',
      )!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.disposeFunction, isNotNull);
      expect(result.disposeFunction!.name, equals('dispose'));
    });

    test(
      'Simple factory without dependencies should have empty dependencies',
      () {
        var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
        final result = dependencyResolver!.resolve(factoryType);
        expect(result.dependencies, isEmpty);
      },
    );

    test('Singleton without dependsOn should have empty dependsOn', () {
      var singletonType = resolvedInput!.library.findType('SimpleSingleton')!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.dependsOn, isEmpty);
    });

    test('Factory as concrete type should have same type and typeImpl', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.type, equals(result.typeImpl));
    });

    test('Non-async factory should have false isAsync', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.isAsync, isFalse);
    });

    test(
      'Factory with unnamed constructor should have empty constructorName',
      () {
        var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
        final result = dependencyResolver!.resolve(factoryType);
        expect(result.constructorName, isEmpty);
      },
    );

    test('LazySingleton should have correct injectable type', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'SimpleLazySingleton',
      )!;
      final result = dependencyResolver!.resolve(lazySingletonType);
      expect(result.injectableType, equals(InjectableType.lazySingleton));
    });

    test('Singleton should have correct injectable type', () {
      var singletonType = resolvedInput!.library.findType('SimpleSingleton')!;
      final result = dependencyResolver!.resolve(singletonType);
      expect(result.injectableType, equals(InjectableType.singleton));
    });

    test('Factory should have correct injectable type', () {
      var factoryType = resolvedInput!.library.findType('SimpleFactory')!;
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.injectableType, equals(InjectableType.factory));
    });

    test('LazySingleton with external class dispose function', () {
      var lazySingletonType = resolvedInput!.library.findType(
        'LazySingletonWithExternalDispose',
      )!;
      final type = ImportableType(
        name: 'LazySingletonWithExternalDispose',
        import: 'source.dart',
      );
      final result = dependencyResolver!.resolve(lazySingletonType);
      expect(result.type, equals(type));
      expect(result.typeImpl, equals(type));
      expect(result.injectableType, equals(InjectableType.lazySingleton));
      expect(result.disposeFunction, isNotNull);
      expect(
        result.disposeFunction!.name,
        equals('disposeExternal'),
      );
    });

    test('Factory with nested record param', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNestedRecord',
      )!;
      final type = ImportableType(
        name: 'FactoryWithNestedRecord',
        import: 'source.dart',
      );
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.type, equals(type));
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies.first.paramName, equals('record'));
      expect(result.dependencies.first.type.name, equals('NestedRecord'));
    });

    test('Factory with generic containing inline record', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithGenericRecordArg',
      )!;
      final type = ImportableType(
        name: 'FactoryWithGenericRecordArg',
        import: 'source.dart',
      );
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.type, equals(type));
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies.first.type.name, equals('List'));
      expect(result.dependencies.first.type.typeArguments, hasLength(1));
      expect(
        result.dependencies.first.type.typeArguments.first.isRecordType,
        isTrue,
      );
    });

    test('Factory with nullable record param', () {
      var factoryType = resolvedInput!.library.findType(
        'FactoryWithNullableRecord',
      )!;
      final type = ImportableType(
        name: 'FactoryWithNullableRecord',
        import: 'source.dart',
      );
      final result = dependencyResolver!.resolve(factoryType);
      expect(result.type, equals(type));
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies.first.type.isNullable, isTrue);
      expect(result.dependencies.first.type.isRecordType, isTrue);
    });
  });
}
