import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class FactoryParamGenerator extends RegisterFuncGenerator {
  FactoryParamGenerator(Set<ImportableType> prefixedTypes)
      : super(prefixedTypes);

  @override
  String generate(DependencyConfig dep) {
    final initializer = generateInitializer(dep);

    var asyncStr = dep.isAsync && !dep.preResolve ? 'Async' : '';

    var typeArgs = dep.dependencies.where((d) => d.isFactoryParam).fold<Map>(
        <String, String>{},
        (all, b) => all..[b.paramName] = b.type.getDisplayName(prefixedTypes));
    if (typeArgs.length < 2) {
      typeArgs['_'] = 'dynamic';
    }

    final argsDeclaration =
        '<${dep.type.getDisplayName(prefixedTypes)},${typeArgs.values.join(',')}>';
    final methodParams = typeArgs.keys.join(', ');

    write(
        "gh.factoryParam$asyncStr$argsDeclaration(($methodParams)=> $initializer");

    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
