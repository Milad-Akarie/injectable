import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/factory_param_generator.dart';
import 'package:injectable_generator/generator/lazy_factory_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Factory param generator Test group', () {
    test("One factory param generator test", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            dependencies: [
              InjectedDependency(
                type: 'Storage',
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: true,
              )
            ],
          )),
          'g.registerFactoryParam<Demo,Storage,dynamic>((storage, _)=> Demo(storage));');
    });

    test("Two factory param generator test", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            dependencies: [
              InjectedDependency(
                type: 'Storage',
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: true,
              ),
              InjectedDependency(
                type: 'Url',
                paramName: 'url',
                isFactoryParam: true,
                isPositional: true,
              )
            ],
          )),
          'g.registerFactoryParam<Demo,Storage,Url>((storage, url)=> Demo(storage, url));');
    });

    test("Two named factory param generator test", () {
      expect(
          generate(DependencyConfig(
            type: 'Demo',
            typeImpl: 'Demo',
            dependencies: [
              InjectedDependency(
                type: 'Storage',
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: false,
              ),
              InjectedDependency(
                type: 'Url',
                paramName: 'url',
                isFactoryParam: true,
                isPositional: false,
              )
            ],
          )),
          'g.registerFactoryParam<Demo,Storage,Url>((storage, url)=> Demo(storage: storage, url: url));');
    });

    test("One factory param with injected dependencies test", () {
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
              ),
              InjectedDependency(
                type: 'String',
                paramName: 'url',
                isFactoryParam: true,
                isPositional: true,
              )
            ],
          )),
          'g.registerFactoryParam<Demo,String,dynamic>((url, _)=> Demo(g<Storage>(), url));');
    });
  });
}

String generate(DependencyConfig input) {
  return FactoryParamGenerator().generate(input);
}
