import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/factory_param_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Factory param generator Test group', () {
    test("One factory param generator test", () {
      expect(
          generate(DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: true,
              )
            ],
          )),
          'gh.factoryParam<Demo,Storage,dynamic>((storage, _)=> Demo(storage));');
    });

    test("Two factory param generator test", () {
      expect(
          generate(DependencyConfig(
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
              )
            ],
          )),
          'gh.factoryParam<Demo,Storage,Url>((storage, url)=> Demo(storage, url));');
    });

    test("Two named factory param generator test", () {
      expect(
          generate(DependencyConfig(
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
              )
            ],
          )),
          'gh.factoryParam<Demo,Storage,Url>((storage, url)=> Demo(storage: storage, url: url));');
    });

    test("One factory param with injected dependencies test", () {
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
              ),
              InjectedDependency(
                type: ImportableType(name: 'String'),
                paramName: 'url',
                isFactoryParam: true,
                isPositional: true,
              )
            ],
          )),
          'gh.factoryParam<Demo,String,dynamic>((url, _)=> Demo(get<Storage>(), url));');
    });
  });
}

String generate(
  DependencyConfig input, {
  Set<ImportableType> prefixedTypes = const {},
}) {
  return FactoryParamGenerator(prefixedTypes).generate(input);
}
