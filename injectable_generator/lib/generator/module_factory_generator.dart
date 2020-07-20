import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class ModuleFactoryGenerator extends RegisterFuncGenerator {
  @override
  String generateInitializer(DependencyConfig dep, {String getIt = 'g'}) {
    final flattenedParams = flattenParams(dep.dependencies, getIt);

    final constructorName =
        dep.constructorName != null && dep.constructorName.isNotEmpty
            ? '.${dep.constructorName}'
            : '';

    return '${dep.typeImpl}$constructorName($flattenedParams)';
  }

  @override
  String generate(DependencyConfig dep,
      {String prefix = '', String suffix = ''}) {
    final constructor = generateInitializer(dep, getIt: '_g');
    if (dep.isModuleMethod) {
      return '${dep.typeImpl} ${dep.initializerName}() => $constructor;';
    } else {
      return '${dep.typeImpl} get ${dep.initializerName} => $constructor ;';
    }
  }
}
