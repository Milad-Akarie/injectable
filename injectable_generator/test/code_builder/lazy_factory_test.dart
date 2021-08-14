import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
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

    test("lazy singleton generator with async dependencies", () {
      final dep = DependencyConfig(
        injectableType: InjectableType.lazySingleton,
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
      );
      final allDeps = [
        dep,
        DependencyConfig(
          injectableType: InjectableType.factory,
          type: ImportableType(name: 'Storage'),
          typeImpl: ImportableType(name: 'Storage'),
          isAsync: true,
        )
      ];
      expect(generate(dep, allDeps: allDeps),
          'gh.lazySingletonAsync<Demo>(() async  => Demo( await get.getAsync<Storage>()));');
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

    test("factory generator with async positional dependencies", () {
      final dep = DependencyConfig(
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
      );
      final allDeps = [
        dep,
        DependencyConfig(
          injectableType: InjectableType.factory,
          type: ImportableType(name: 'Storage'),
          typeImpl: ImportableType(name: 'Storage'),
          isAsync: true,
        )
      ];
      expect(generate(dep, allDeps: allDeps),
          'gh.factoryAsync<Demo>(() async  => Demo( await get.getAsync<Storage>()));');
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

    test("factory generator with async named dependencies", () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
              type: ImportableType(name: 'Storage'),
              paramName: 'storage',
              isFactoryParam: false,
              isPositional: false,
              instanceName: 'storageImpl')
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          injectableType: InjectableType.factory,
          type: ImportableType(name: 'Storage'),
          typeImpl: ImportableType(name: 'Storage'),
          instanceName: 'storageImpl',
          isAsync: true,
        ),
      ];
      expect(generate(dep, allDeps: allDeps),
          "gh.factoryAsync<Demo>(() async  => Demo(storage:  await get.getAsync<Storage>(instanceName: 'storageImpl')));");
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

String generate(DependencyConfig input, {List<DependencyConfig>? allDeps}) {
  final generator = LibraryGenerator(
      dependencies: allDeps ?? [], initializerName: 'initGetIt');
  final statement = generator.buildLazyRegisterFun(input);
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  return statement.accept(emitter).toString();
}
