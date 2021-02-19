import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/library_builder.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:test/test.dart';

void main() {
  // This includes registerFactory && registerLazySingleton
  group('Lazy factory Test group', () {
    test("Simple empty constructor generator", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
          )),
          'gh.factory<Demo>(() => Demo());');
    });

    test("Simple lazy singleton generator", () {
      expect(
          generate(
            DependencyConfig(
              injectableType: InjectableType.lazySingleton,
              type: ImportableType(name: 'Demo'),
              typeImpl: ImportableType(name: 'Demo'),
            ),
          ),
          'gh.lazySingleton<Demo>(() => Demo());');
    });

    test("factory generator abstract type != implementation", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'AbstractType'),
            typeImpl: ImportableType(name: 'Demo'),
          )),
          'gh.factory<AbstractType>(() => Demo());');
    });

    test("factory generator async", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: true,
          )),
          'gh.factoryAsync<Demo>(() => Demo());');
    });

    test("factory generator with Positional dependencies", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.factory,
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
          'gh.factory<Demo>(() => Demo(get<Storage>()));');
    });

    test("factory generator with named dependencies", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                  type: ImportableType(name: 'Storage'),
                  paramName: 'storage',
                  isFactoryParam: false,
                  isPositional: false,
                  instanceName: "storageImpl")
            ],
          )),
          "gh.factory<Demo>(() => Demo(storage: get<Storage>(instanceName: 'storageImpl')));");
    });

    test("factory generator with parameterized type", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.factory,
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
          "gh.factory<Demo<String>>(() => Demo(storage: get<Storage>()));");
    });
  });
}

String generate(DependencyConfig input) {
  final statement = buildLazyRegisterFun(input);
  final emitter = DartEmitter(Allocator.none, true, true);
  return statement.accept(emitter).toString();
}
