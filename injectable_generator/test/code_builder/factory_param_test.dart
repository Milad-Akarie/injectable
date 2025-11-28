import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:test/test.dart';

void main() {
  group('Factory param generator Test group', () {
    test("One factory param generator test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: true,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, Storage, dynamic>((storage, _, ) => Demo(storage));',
      );
    });

    test("Two factory param generator test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: true,
              ),
              InjectedDependency(
                type: ImportableType(name: 'Url'),
                paramName: 'url',
                isFactoryParam: true,
                isPositional: true,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, Storage, Url>((storage, url, ) => Demo(storage, url, ));',
      );
    });

    test("Two named factory param generator test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: false,
              ),
              InjectedDependency(
                type: ImportableType(name: 'Url'),
                paramName: 'url',
                isFactoryParam: true,
                isPositional: false,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, Storage, Url>((storage, url, ) => Demo(storage: storage, url: url, ));',
      );
    });

    test("One factory param with injected dependencies test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: false,
                isPositional: true,
              ),
              InjectedDependency(
                type: ImportableType(name: 'String'),
                paramName: 'url',
                isFactoryParam: true,
                isPositional: true,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, String, dynamic>((url, _, ) => Demo(gh<Storage>(), url, ));',
      );
    });

    test("One factory param with injected async dependencies test", () {
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
          ),
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'url',
            isFactoryParam: true,
            isPositional: true,
          ),
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
      expect(
        generate(dep, allDeps: allDeps),
        'gh.factoryParamAsync<Demo, String, dynamic>((url, _, ) async  => Demo( await gh.getAsync<Storage>(), url, ));',
      );
    });
  });
}

String generate(DependencyConfig input, {List<DependencyConfig>? allDeps}) {
  final generator = InitMethodGenerator(
    scopeDependencies: allDeps ?? [],
    allDependencies: DependencyList(dependencies: allDeps ?? []),
    initializerName: 'init',
  );
  final statement = generator.buildLazyRegisterFun(input);
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  return statement.accept(emitter).toString();
}
