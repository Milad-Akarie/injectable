import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class ModuleFactoryGenerator extends RegisterFuncGenerator {
  ModuleFactoryGenerator(Set<ImportableType> prefixedTypes) : super(prefixedTypes);

  @override
  String generateInitializer(DependencyConfig dep, {String getIt = 'get'}) {
    final flattenedParams = flattenParams(dep.dependencies, getIt);
    final constructorName = dep.constructorName != null && dep.constructorName.isNotEmpty ? '.${dep.constructorName}' : '';
    return '${dep.typeImpl.getDisplayName(prefixedTypes, includeTypeArgs: false)}$constructorName($flattenedParams)';
  }

  @override
  String generate(DependencyConfig dep, {Set<ImportableType> prefixedTypes}) {
    final constructor = generateInitializer(dep, getIt: '_get');
    if (dep.isModuleMethod) {
      return '${dep.typeImpl.getDisplayName(prefixedTypes)} ${dep.initializerName}() => $constructor;';
    } else {
      return '${dep.typeImpl.getDisplayName(prefixedTypes)} get ${dep.initializerName} => $constructor ;';
    }
  }
}
