import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class FactoryParamGenerator extends RegisterFuncGenerator {
  @override
  String generate(DependencyConfig dep) {
    final constructBody = dep.moduleConfig == null
        ? generateConstructor(dep)
        : generateConstructorForModule(dep);

    var asyncStr = dep.isAsync && !dep.preResolve ? 'Async' : '';

    var typeArgs = dep.dependencies
        .where((d) => d.isFactoryParam)
        .fold<Map>(<String, String>{}, (all, b) => all..[b.paramName] = b.type);
    if (typeArgs.length < 2) {
      typeArgs['_'] = 'dynamic';
    }

    final argsDeclaration = '<${dep.type},${typeArgs.values.join(',')} >';
    final methodParams = typeArgs.keys.join(',');

    writeln(
        "g.registerFactoryParam$asyncStr$argsDeclaration(($methodParams)=> $constructBody,");

    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
