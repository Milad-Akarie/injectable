import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/utils.dart';

abstract class RegisterFuncGenerator {
  final buffer = StringBuffer();

  write(Object o) => buffer.write(o);
  writeln(Object o) => buffer.writeln(o);
  String generate(DependencyConfig dep);
  String generateConstructor(DependencyConfig dep, {String getIt = 'g'}) {
    final params = dep.dependencies.map((injectedDep) {
      var type = '<${injectedDep.type}>';
      var instanceName = '';
      if (injectedDep.name != null) {
        instanceName = "'${injectedDep.name}'";
      }
      final paramName =
          (!injectedDep.isPositional) ? '${injectedDep.paramName}:' : '';

      if (injectedDep.isFactoryParam) {
        return '$paramName${injectedDep.paramName}';
      } else {
        return '${paramName}$getIt$type($instanceName)';
      }
    }).toList();

    final constructName =
        dep.constructorName.isEmpty ? "" : ".${dep.constructorName}";
    if (params.length > 2) {
      params.add('');
    }
    return '${stripGenericTypes(dep.bindTo)}$constructName(${params.join(',')})';
  }

  String generateAwaitSetup(DependencyConfig dep, String constructBody) {
    final awaitedVar = toCamelCase(stripGenericTypes(dep.type));
    writeln('final $awaitedVar = await $constructBody;');
    return awaitedVar;
  }

  String generateConstructorForModule(DependencyConfig dep) {
    final mConfig = dep.moduleConfig;
    final mName = toCamelCase(mConfig.moduleName);

    var initializr = StringBuffer()..write(mConfig.name);
    if (mConfig.isMethod) {
      initializr.write('(');
      initializr.write(mConfig.params.keys.join(','));
      initializr.write(')');
    }

    return '$mName.${initializr.toString()}';
  }

  void closeRegisterFunc(DependencyConfig dep) {
    if (dep.signalsReady != null) {
      write(',signalsReady: ${dep.signalsReady}');
    }
    if (dep.instanceName != null) {
      write(",instanceName: '${dep.instanceName}'");
    }
    write(");");
  }
}
