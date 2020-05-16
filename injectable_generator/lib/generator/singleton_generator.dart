import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class SingletonGenerator extends RegisterFuncGenerator {
  @override
  String generate(DependencyConfig dep) {
    final initializer = generateInitializer(dep);

    var constructor = initializer;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, initializer);
    }

    final typeArg = '<${dep.type}>';

    if (dep.isAsync && !dep.preResolve) {
      write('g.registerSingletonAsync$typeArg(()=> $constructor');
      if (dep.dependsOn.isNotEmpty) {
        write(', dependsOn: ${dep.dependsOn}');
      }
    } else {
      if (dep.dependsOn.isEmpty) {
        write("g.registerSingleton$typeArg($constructor");
      } else {
        write(
            'g.registerSingletonWithDependencies$typeArg(()=> $constructor, dependsOn: ${dep.dependsOn}');
      }
    }

    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
