// Todo add more resolver tests
import 'package:analyzer/dart/element/element.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
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
  group('Dependency Resolver', () {
    ResolvedInput? resolvedInput;
    DependencyResolver? dependencyResolver;

    setUp(() async {
      resolvedInput = await resolveInput('test/resolver/samples/source.dart');
      dependencyResolver = DependencyResolver(MockTypeResolver());
    });

    test('Factory without annotation', () {
      var factoryWithoutAnnotationType = resolvedInput!.library.findType(
        'FactoryWithoutAnnotation',
      )!;

      final type = ImportableType(
        name: 'FactoryWithoutAnnotation',
        import: 'source.dart',
      );
      expect(
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          constructorName: 'valid',
        ),
        equals(dependencyResolver!.resolve(factoryWithoutAnnotationType)),
      );
    });

    test('Simple Factory no dependencies', () {
      var simpleFactoryType = resolvedInput!.library.findType('SimpleFactory')!;

      final type = ImportableType(name: 'SimpleFactory', import: 'source.dart');
      expect(
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
        ),
        equals(dependencyResolver!.resolve(simpleFactoryType)),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: dependencyType,
              paramName: 'simpleFactory',
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: dependencyType,
              paramName: 'simpleFactory',
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: dependencyType,
              paramName: 'simpleFactory',
              isFactoryParam: true,
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: dependencyType,
              paramName: 'simpleFactory',
              isPositional: true,
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'NamedRecord', import: 'source.dart'),
              paramName: 'record',
              isFactoryParam: true,
              isPositional: true,
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
                  ImportableType(name: 'SimpleFactory', import: 'source.dart'),
                  ImportableType(name: 'int', import: 'source.dart'),
                ],
              ),
              paramName: 'record',
              isFactoryParam: true,
              isPositional: true,
            ),
          ],
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: typeImpl,
          injectableType: InjectableType.factory,
        ),
        equals(dependencyResolver!.resolve(factoryAsAbstract)),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [],
          isAsync: false,
          constructorName: 'namedFactory',
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [],
          isAsync: false,
          constructorName: 'namedFactory',
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: dependencyType,
              paramName: 'simpleFactory',
              isFactoryParam: true,
            ),
          ],
          isAsync: true,
          constructorName: 'create',
        ),
        dependencyResolver!.resolve(factoryWithDeps),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          orderPosition: 1,
          canBeConst: true,
        ),
        equals(dependencyResolver!.resolve(simpleFactoryType)),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          orderPosition: 1,
          canBeConst: true,
        ),
        equals(dependencyResolver!.resolve(simpleFactoryType)),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          scope: 'scope',
          canBeConst: true,
        ),
        equals(dependencyResolver!.resolve(simpleFactoryType)),
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
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          scope: 'scope',
          canBeConst: true,
        ),
        equals(dependencyResolver!.resolve(simpleFactoryType)),
      );
    });

    test('Const injectable with no deps can generate const instances', () {
      var simpleFactoryType = resolvedInput!.library.findType('ConstService')!;
      final type = ImportableType(name: 'ConstService', import: 'source.dart');
      expect(
        DependencyConfig(
          type: type,
          typeImpl: type,
          injectableType: InjectableType.factory,
          canBeConst: true,
        ),
        equals(dependencyResolver!.resolve(simpleFactoryType)),
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
            ),
          ],
          injectableType: InjectableType.factory,
          canBeConst: false,
        ),
        equals(dependencyResolver!.resolve(simpleFactoryType)),
      );
    });
  });
}
