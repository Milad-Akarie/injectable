import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/factory_generator.dart';

class LazySingletonGenerator extends FactoryGenerator {
  @override
  String generate(DependencyConfig dep) {
    final initializer = generateInitializer(dep);

    var constructor = initializer;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, initializer);
    }

    final asyncStr = dep.isAsync && !dep.preResolve ? 'Async' : '';
    writeln("g.registerLazySingleton$asyncStr<${dep.type}>(()=> $constructor");
    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
