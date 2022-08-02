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
  String? resolveImport(Element? element) {
    return 'source.dart';
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

    test('Simple Factory no dependencies', () {
      var simpleFactoryType = resolvedInput!.library.findType('SimpleFactory')!;

      final type = ImportableType(
        name: 'SimpleFactory',
        import: 'source.dart',
      );
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
      final FactoryWithDeps =
          resolvedInput!.library.findType('FactoryWithNullableDeps')!;
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
              )
            ]),
        dependencyResolver!.resolve(FactoryWithDeps),
      );
    });

    test('Factory with dependencies', () {
      final FactoryWithDeps =
          resolvedInput!.library.findType('FactoryWithDeps')!;
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
              )
            ]),
        dependencyResolver!.resolve(FactoryWithDeps),
      );
    });

    test('Factory with nullable factoryParams', () {
      final FactoryWithDeps =
          resolvedInput!.library.findType('FactoryWithNullableFactoryParams')!;
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
              )
            ]),
        dependencyResolver!.resolve(FactoryWithDeps),
      );
    });

    test('Factory with factoryParams', () {
      final FactoryWithDeps =
          resolvedInput!.library.findType('FactoryWithFactoryParams')!;
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
              )
            ]),
        dependencyResolver!.resolve(FactoryWithDeps),
      );
    });

    test('Simple Factory as abstract no dependencies', () {
      var factoryAsAbstract =
          resolvedInput!.library.findType('FactoryAsAbstract')!;

      final type = ImportableType(
        name: 'IFactory',
        import: 'source.dart',
      );

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

    test('Async factory with nullable dependencies', () {
      final FactoryWithDeps =
          resolvedInput!.library.findType('AsyncFactoryWithNullableDeps')!;
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
              )
            ],
            isAsync: true,
            constructorName: 'create'),
        dependencyResolver!.resolve(FactoryWithDeps),
      );
    });

    test('Async factory with non nullable dependencies', () {
      final FactoryWithDeps =
          resolvedInput!.library.findType('AsyncFactoryWithNonNullableDeps')!;
      final errorMessage = 'Async factory params must be nullable';
      var resultError;
      try {
        dependencyResolver!.resolve(FactoryWithDeps);
      } catch (error) {
        resultError = error as InvalidGenerationSourceError;
      }
      expect(resultError.message, errorMessage);
    });
  });
}
