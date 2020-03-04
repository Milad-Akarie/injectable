import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';
import 'package:injectable_generator/utils.dart';

class ModuleFactoryGenerator extends RegisterFuncGenerator {
  @override
  String generate(DependencyConfig dep) {
    final constructor = generateConstructor(dep, getIt: '_g');
    if (dep.moduleConfig.isMethod) {
      throwBoxedIf(
          dep.moduleConfig.params.isNotEmpty,
          'Error generating [${dep.type}]! Dependencies with factoryParam methods must have a custom initializer.'
          '\nDependency getDep(String p1,int p2) => Dependency(p1,p2);');

      return '${dep.bindTo} ${dep.moduleConfig.name}() => $constructor;';
    } else {
      return '${dep.bindTo} get ${dep.moduleConfig.name} => $constructor ;';
    }
  }
}
