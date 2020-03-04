import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class FactoryGenerator extends RegisterFuncGenerator {
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
    writeln("g.registerFactory$asyncStr<${dep.type}>(()=> $constructor");
    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
