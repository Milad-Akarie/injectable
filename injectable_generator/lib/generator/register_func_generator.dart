import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/utils.dart';

abstract class RegisterFuncGenerator {
  final buffer = StringBuffer();

  write(Object o) => buffer.write(o);
  writeln(Object o) => buffer.writeln(o);
  String generate(DependencyConfig dep);
  String generateConstructor(DependencyConfig dep, {String getIt = 'g'}) {
    final constBuffer = StringBuffer();
    dep.dependencies.asMap().forEach((i, injectedDep) {
      String type = '<${injectedDep.type}>';
      String instanceName = '';
      if (injectedDep.name != null) {
        instanceName = "'${injectedDep.name}'";
      }
      final paramName =
          (injectedDep.paramName != null) ? '${injectedDep.paramName}:' : '';
      constBuffer.write("${paramName}$getIt$type($instanceName),");
    });

    final constructName =
        dep.constructorName.isEmpty ? "" : ".${dep.constructorName}";

    if (dep.regsiterAsInstance) {
      final awaitedVar = toCamelCase(stripGenericTypes(dep.type));
      writeln(
          'final $awaitedVar = await ${stripGenericTypes(dep.bindTo)}$constructName(${constBuffer.toString()});');
      return awaitedVar;
    } else {
      return '${stripGenericTypes(dep.bindTo)}$constructName(${constBuffer.toString()})';
    }
  }

  String generateConstructorForModule(DependencyConfig dep) {
    final mConfig = dep.moduleConfig;
    final mName = toCamelCase(mConfig.moduleName);
    print(dep.regsiterAsInstance);
    if (dep.regsiterAsInstance) {
      final awaitedVar = toCamelCase(stripGenericTypes(dep.type));
      writeln('final $awaitedVar = await $mName.${mConfig.name};');
      return awaitedVar;
    } else {
      return '$mName.${mConfig.name}';
    }
  }
}
