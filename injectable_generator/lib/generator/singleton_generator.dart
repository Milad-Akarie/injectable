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
      writeln('g.registerSingletonAsync$typeArg(()=> $constructor');
      if (dep.dependsOn.isNotEmpty) {
        write(', dependsOn:${dep.dependsOn}');
      }
    } else {
      if (dep.dependsOn.isEmpty) {
        writeln("g.registerSingleton$typeArg($constructor");
      } else {
        writeln(
            'g.registerSingletonWithDependencies$typeArg(()=> $constructor, dependsOn:${dep.dependsOn}');
      }
    }

    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
