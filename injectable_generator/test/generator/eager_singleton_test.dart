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
          'singleton<Demo>(Demo())');
    });

    test("Singleton generator abstract", () {
      expect(
        generate(DependencyConfig(
          type: 'AbstractType',
          typeImpl: 'Demo',
        )),
        'singleton<AbstractType>(Demo())',
      );
    });

    test("Singleton generator with instanceName", () {
      expect(
        generate(DependencyConfig(
          type: 'Demo',
          typeImpl: 'Demo',
          instanceName: 'MyDemo',
        )),
        "singleton<Demo>(Demo(), instanceName: 'MyDemo')",
      );
    });

    test("Singleton generator async", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            isAsync: true,
          )),
          'singletonAsync<Demo>(()=> Demo())');
    });

    test("Singleton generator async with dependsOn", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            isAsync: true,
            dependsOn: ['Storage', 'LocalRepo'],
          )),
          "singletonAsync<Demo>(()=> Demo(), dependsOn: [Storage, LocalRepo])");
    });

    test("Singleton generator with dependsOn", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            isAsync: false,
            dependsOn: ['Storage', 'LocalRepo'],
          )),
          'singletonWithDependencies<Demo>(()=> Demo(), dependsOn: [Storage, LocalRepo])');
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
          'singleton<Demo>(Demo(g<Storage>()))');
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
          'singleton<Demo>(Demo(storage: g<Storage>()))');
    });
  });
}

String generate(DependencyConfig input) {
  return SingletonGenerator().generate(input);
}
