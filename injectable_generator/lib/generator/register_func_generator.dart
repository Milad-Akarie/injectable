import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/config_code_generator.dart';
import 'package:injectable_generator/utils.dart';

abstract class RegisterFuncGenerator {
  final buffer = StringBuffer();
  final Set<ImportableType> prefixedTypes;

  RegisterFuncGenerator(this.prefixedTypes);

  write(Object o) => buffer.write(o);

  writeln(Object o) => buffer.writeln(o);

  String generate(DependencyConfig dep);

  String generateInitializer(DependencyConfig dep, {String getIt = 'g'}) {
    final flattenedParams = flattenParams(dep.dependencies, getIt);

    if (dep.isFromModule) {
      final moduleName = toCamelCase(dep.module.name);
      if (!dep.isModuleMethod) {
        return '$moduleName.${dep.initializerName}';
      } else {
        if (dep.isAbstract) {
          return '$moduleName.${dep.initializerName}()';
        } else {
          return '${moduleName}.${dep.initializerName}($flattenedParams)';
        }
      }
    }

    final typeName = dep.typeImpl.getDisplayName(prefixedTypes);
    final constructorName = dep.constructorName != null && dep.constructorName.isNotEmpty ? '.${dep.constructorName}' : '';

    return '${typeName}$constructorName($flattenedParams)';
  }

  String flattenParams(List<InjectedDependency> deps, String getIt) {
    final params = deps.map((injectedDep) {
      var type = injectedDep.type.name == 'dynamic'
          ? ''
          : '<${injectedDep.type.getDisplayName(prefixedTypes)}>';
      var instanceName = '';

      if (injectedDep.name != null) {
        instanceName = "instanceName: '${injectedDep.name}'";
      }

      final paramName =
      (!injectedDep.isPositional) ? '${injectedDep.paramName}: ' : '';

      if (injectedDep.isFactoryParam) {
        return '$paramName${injectedDep.paramName}';
      } else {
        return '$paramName$getIt$type($instanceName)';
      }
    }).toList();

    if (params.length > 2) {
      params.add('');
    }
    return params.join(', ');
  }

  String generateAwaitSetup(DependencyConfig dep, String constructBody) {
    var awaitedVar = toCamelCase(dep.type.name);
    if (registeredVarNames.contains(awaitedVar)) {
      awaitedVar =
      '$awaitedVar${registeredVarNames
          .where((i) => i.startsWith(awaitedVar))
          .length}';
    }
    registeredVarNames.add(awaitedVar);

    writeln('final $awaitedVar = await $constructBody;');
    return awaitedVar;
  }

  void closeRegisterFunc(DependencyConfig dep) {
    if (dep.signalsReady != null) {
      write(', signalsReady: ${dep.signalsReady}');
    }
    if (dep.instanceName != null) {
      write(", instanceName: '${dep.instanceName}'");
    }
    if (dep.environments?.isNotEmpty == true) {
      write(
          ", registerFor: {${dep.environments.toSet().map((e) => "_$e").join(',')}}");
    }
    write(");");
  }
}
