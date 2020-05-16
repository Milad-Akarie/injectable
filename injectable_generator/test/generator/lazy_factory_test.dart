import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/lazy_factory_generator.dart';
import 'package:test/test.dart';

void main() {
  // This includes registerFactory && registerLazySingleton
  group('Lazy factory Test group', () {
    test("Simple empty constructor generator", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
          )),
          'g.registerFactory<Demo>(()=> Demo());');
    });

    test("Simple lazy singleton generator", () {
      expect(
          generate(
              DependencyConfig(
                type: 'Demo',
                typeImpl: 'Demo',
              ),
              isLazySingleton: true),
          'g.registerLazySingleton<Demo>(()=> Demo());');
    });

    test("factory generator abstract", () {
      expect(
          generate(DependencyConfig(
            type: 'AbstractType',
            typeImpl: 'Demo',
          )),
          'g.registerFactory<AbstractType>(()=> Demo());');
    });

    test("factory generator async", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            isAsync: true,
          )),
          'g.registerFactoryAsync<Demo>(()=> Demo());');
    });

    test("factory generator with Positional dependencies", () {
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
          'g.registerFactory<Demo>(()=> Demo(g<Storage>()));');
    });

    test("factory generator with named dependencies", () {
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
          'g.registerFactory<Demo>(()=> Demo(storage: g<Storage>()));');
    });
  });
}

String generate(DependencyConfig input, {bool isLazySingleton = false}) {
  return LazyFactoryGenerator(isLazySingleton: isLazySingleton).generate(input);
}
