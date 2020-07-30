import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class SingletonGenerator extends RegisterFuncGenerator {
  SingletonGenerator(Set<ImportableType> prefixedTypes) : super(prefixedTypes);

  @override
  String generate(DependencyConfig dep) {
    final initializer = generateInitializer(dep);

    var constructor = initializer;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, initializer);
    }

    final typeArg = '<${dep.type.getDisplayName(prefixedTypes)}>';

    if (dep.isAsync && !dep.preResolve) {
      write('gh.singletonAsync$typeArg(()=> $constructor');
      if (dep.dependsOn.isNotEmpty) {
        write(', dependsOn: ${dep.dependsOn}');
      }
    } else {
      if (dep.dependsOn.isEmpty) {
        write("gh.singleton$typeArg($constructor");
      } else {
        write('gh.singletonWithDependencies$typeArg(()=> $constructor, dependsOn: ${dep.dependsOn}');
      }
    }

    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
