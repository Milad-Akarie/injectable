import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/lazy_factory_generator.dart';
import 'package:test/test.dart';

void main() {
  // This includes registerFactory && registerLazySingleton
  group('Lazy factory Test group', () {
    test("Simple empty constructor generator", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
          )),
          'gh.factory<Demo>(()=> Demo());');
    });

    test("Simple lazy singleton generator", () {
      expect(
          generate(
              DependencyConfig(
                type: ImportableType(name: 'Demo'),
                typeImpl: ImportableType(name: 'Demo'),
              ),
              isLazySingleton: true),
          'gh.lazySingleton<Demo>(()=> Demo());');
    });

    test("factory generator abstract", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'AbstractType'),
            typeImpl: ImportableType(name: 'Demo'),
          )),
          'gh.factory<AbstractType>(()=> Demo());');
    });

    test("factory generator async", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: true,
          )),
          'gh.factoryAsync<Demo>(()=> Demo());');
    });

    test("factory generator with Positional dependencies", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: false,
                isPositional: true,
              )
            ],
          )),
          'gh.factory<Demo>(()=> Demo(g<Storage>()));');
    });

    test("factory generator with named dependencies", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                  type: ImportableType(name: 'Storage'),
                  paramName: 'storage',
                  isFactoryParam: false,
                  isPositional: false,
                  name: "storageImpl")
            ],
          )),
          "gh.factory<Demo>(()=> Demo(storage: g<Storage>(instanceName: 'storageImpl')));");
    });

    test("factory generator with parameterized type", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo', typeArguments: [
              ImportableType(name: 'String'),
            ]),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: false,
                isPositional: false,
              )
            ],
          )),
          "gh.factory<Demo<String>>(()=> Demo(storage: g<Storage>()));");
    });

    test("factory generator with prefixed types", () {
      var demo = ImportableType(name: 'Demo');
      expect(
          generate(
              DependencyConfig(
                type: demo,
                typeImpl: demo,
                dependencies: [
                  InjectedDependency(
                    type: ImportableType(name: 'Storage'),
                    paramName: 'storage',
                    isFactoryParam: false,
                    isPositional: false,
                  )
                ],
              ),
              prefixedTypes: {demo.copyWith(prefix: 'prefix')}),
          "gh.factory<prefix.Demo>(()=> prefix.Demo(storage: g<Storage>()));");
    });
  });
}

String generate(
  DependencyConfig input, {
  bool isLazySingleton = false,
  Set<ImportableType> prefixedTypes = const {},
}) {
  return LazyFactoryGenerator(prefixedTypes, isLazySingleton: isLazySingleton).generate(input);
}
