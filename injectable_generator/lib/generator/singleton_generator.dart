import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class SingletonGenerator extends RegisterFuncGenerator {
  @override
  String generate(DependencyConfig dep,
      {String prefix = '', String suffix = ''}) {
    final initializer = generateInitializer(dep);

    var constructor = initializer;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, initializer);
    }

    final typeArg = '<${dep.type}>';

    if (dep.isAsync && !dep.preResolve) {
      write('${prefix}singletonAsync$typeArg(()=> $constructor');
      if (dep.dependsOn.isNotEmpty) {
        write(', dependsOn: ${dep.dependsOn}');
      }
    } else {
      if (dep.dependsOn.isEmpty) {
        write("${prefix}singleton$typeArg($constructor");
      } else {
        write(
            '${prefix}singletonWithDependencies$typeArg(()=> $constructor, dependsOn: ${dep.dependsOn}');
      }
    }

    closeRegisterFunc(dep, suffix);
    return buffer.toString();
  }
}
