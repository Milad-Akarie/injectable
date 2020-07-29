import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/singleton_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Eager singleton Test group', () {
    test("Simple empty constructor generator", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
          )),
          'gh.singleton<Demo>(Demo())');
    });

    test("Singleton generator abstract", () {
      expect(
        generate(DependencyConfig(
          type: ImportableType(name: 'AbstractType'),
          typeImpl: ImportableType(name: 'Demo'),
        )),
        'gh.singleton<AbstractType>(Demo())',
      );
    });

    test("Singleton generator with instanceName", () {
      expect(
        generate(DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          instanceName: 'MyDemo',
        )),
        "gh.singleton<Demo>(Demo(), instanceName: 'MyDemo')",
      );
    });

    test("Singleton generator async", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: true,
          )),
          'singletonAsync<Demo>(()=> Demo())');
    });

    test("Singleton generator async with dependsOn", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: true,
            dependsOn: ['Storage', 'LocalRepo'],
          )),
          "singletonAsync<Demo>(()=> Demo(), dependsOn: [Storage, LocalRepo])");
    });

    test("Singleton generator with dependsOn", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: false,
            dependsOn: ['Storage', 'LocalRepo'],
          )),
          'gh.singletonWithDependencies<Demo>(()=> Demo(), dependsOn: [Storage, LocalRepo]);');
    });

    test("Singleton generator with Positional dependencies", () {
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
          'gh.singleton<Demo>(Demo(g<Storage>()));');
    });

    test("Singleton generator with named dependencies", () {
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
              )
            ],
          )),
          'gh.singleton<Demo>(Demo(storage: g<Storage>()));');
    });
  });
}

String generate(DependencyConfig input) {
  return SingletonGenerator({}).generate(input);
}
