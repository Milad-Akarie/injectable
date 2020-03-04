import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/factory_generator.dart';

class LazySingletonGenerator extends FactoryGenerator {
  @override
  String generate(DependencyConfig dep) {
    final constructBody = dep.moduleConfig == null
        ? generateConstructor(dep)
        : generateConstructorForModule(dep);

    var constructor = constructBody;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, constructBody);
    }

    final asyncStr = dep.isAsync && !dep.preResolve ? 'Async' : '';
    writeln("g.registerLazySingleton$asyncStr<${dep.type}>(()=> $constructor");
    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
