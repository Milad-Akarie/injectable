import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:test/test.dart';

void main() {
  group('Eager singleton Test group', () {
    test("Simple empty constructor generator", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.singleton,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
          )),
          'gh.singleton<Demo>(Demo());');
    });

    test("Singleton generator abstract", () {
      expect(
        generate(DependencyConfig(
          injectableType: InjectableType.singleton,
          type: ImportableType(name: 'AbstractType'),
          typeImpl: ImportableType(name: 'Demo'),
        )),
        'gh.singleton<AbstractType>(Demo());',
      );
    });

    test("Singleton generator with instanceName", () {
      expect(
        generate(DependencyConfig(
          injectableType: InjectableType.singleton,
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          instanceName: 'MyDemo',
        )),
        "gh.singleton<Demo>(Demo(), instanceName: 'MyDemo');",
      );
    });

    test("Singleton generator async", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.singleton,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: true,
          )),
          'gh.singletonAsync<Demo>(() => Demo());');
    });

    test("Singleton generator async with dependsOn", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.singleton,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: true,
            dependsOn: [
              ImportableType(name: 'Storage'),
              ImportableType(name: 'LocalRepo')
            ],
          )),
          "gh.singletonAsync<Demo>(() => Demo(), dependsOn: [Storage, LocalRepo]);");
    });

    test("Singleton generator with dependsOn", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.singleton,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            isAsync: false,
            dependsOn: [
              ImportableType(name: 'Storage'),
              ImportableType(name: 'LocalRepo')
            ],
          )),
          'gh.singletonWithDependencies<Demo>(() => Demo(), dependsOn: [Storage, LocalRepo]);');
    });

    test("Singleton generator with Positional dependencies", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.singleton,
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
          'gh.singleton<Demo>(Demo(gh<Storage>()));');
    });

    test("Singleton generator with async Positional dependencies", () {
      final dep = DependencyConfig(
        injectableType: InjectableType.singleton,
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
        ),
      ];
      expect(generate(dep, allDeps: allDeps),
          'gh.singletonAsync<Demo>(() async  => Demo( await gh.getAsync<Storage>()));');
    });

    test("Singleton generator with named dependencies", () {
      expect(
          generate(DependencyConfig(
            injectableType: InjectableType.singleton,
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
          'gh.singleton<Demo>(Demo(storage: gh<Storage>()));');
    });

    test("Singleton generator with async named dependencies", () {
      final dep = DependencyConfig(
        injectableType: InjectableType.singleton,
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Storage'),
            paramName: 'storage',
            isFactoryParam: false,
            isPositional: false,
            instanceName: 'storageImpl',
          )
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
          'gh.singletonAsync<Demo>(() async  => Demo(storage:  await gh.getAsync<Storage>(instanceName: \'storageImpl\')));');
    });
    test("Singleton generator with async & preResolve named dependencies", () {
      final dep = DependencyConfig(
        injectableType: InjectableType.singleton,
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Storage'),
            paramName: 'storage',
            isFactoryParam: false,
            isPositional: false,
            instanceName: 'storageImpl',
          )
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
          preResolve: true,
        ),
      ];
      expect(generate(dep, allDeps: allDeps),
          'gh.singleton<Demo>(Demo(storage: gh<Storage>(instanceName: \'storageImpl\')));');
    });
  });
}

String generate(DependencyConfig input, {List<DependencyConfig>? allDeps}) {
  final generator = InitMethodGenerator(
    scopeDependencies: allDeps ?? [],
    allDependencies: allDeps?.toSet() ?? {},
    initializerName: 'init',
  );
  final statement = generator.buildSingletonRegisterFun(input);
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  return statement.accept(emitter).toString();
}
