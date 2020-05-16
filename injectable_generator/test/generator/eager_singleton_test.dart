import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/singleton_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Eager singleton Test group', () {
    test("Simple empty constructor generator", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
          )),
          'g.registerSingleton<Demo>(Demo());');
    });

    test("Singleton generator abstract", () {
      expect(
        generate(DependencyConfig(
          type: 'AbstractType',
          typeImpl: 'Demo',
        )),
        'g.registerSingleton<AbstractType>(Demo());',
      );
    });

    test("Singleton generator with instanceName", () {
      expect(
        generate(DependencyConfig(
          type: 'Demo',
          typeImpl: 'Demo',
          instanceName: 'MyDemo',
        )),
        "g.registerSingleton<Demo>(Demo(), instanceName: 'MyDemo');",
      );
    });

    test("Singleton generator async", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            isAsync: true,
          )),
          'g.registerSingletonAsync<Demo>(()=> Demo());');
    });

    test("Singleton generator async with dependsOn", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            isAsync: true,
            dependsOn: ['Storage', 'LocalRepo'],
          )),
          "g.registerSingletonAsync<Demo>(()=> Demo(), dependsOn: [Storage, LocalRepo]);");
    });

    test("Singleton generator with dependsOn", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            isAsync: false,
            dependsOn: ['Storage', 'LocalRepo'],
          )),
          'g.registerSingletonWithDependencies<Demo>(()=> Demo(), dependsOn: [Storage, LocalRepo]);');
    });

    test("Singleton generator with Positional dependencies", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            dependencies: [
              InjectedDependency(
                type: 'Storage',
                paramName: 'storage',
                isFactoryParam: false,
                isPositional: true,
              )
            ],
          )),
          'g.registerSingleton<Demo>(Demo(g<Storage>()));');
    });

    test("Singleton generator with named dependencies", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            dependencies: [
              InjectedDependency(
                type: 'Storage',
                paramName: 'storage',
                isFactoryParam: false,
                isPositional: false,
              )
            ],
          )),
          'g.registerSingleton<Demo>(Demo(storage: g<Storage>()));');
    });
  });
}

String generate(DependencyConfig input) {
  return SingletonGenerator().generate(input);
}
