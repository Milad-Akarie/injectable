import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';
import 'package:injectable_generator/utils.dart';

class SingletonGenerator extends RegisterFuncGenerator {
  @override
  String generate(DependencyConfig dep) {
    final constructBody = dep.moduleConfig == null
        ? generateConstructor(dep)
        : generateConstructorForModule(dep);

    final typeArg = '<${dep.type}>';
    if (dep.dependencies.isNotEmpty) {
      final suffix =
          dep.isAsync && !dep.asInstance ? 'Async' : 'WithDependencies';
      final dependsOn =
          dep.dependencies.map((d) => stripGenericTypes(d.type)).toList();
      writeln(
          "g.registerSingleton$suffix$typeArg(()=> $constructBody, dependsOn:$dependsOn");
    } else {
      if (dep.isAsync && !dep.asInstance) {
        writeln("g.registerSingletonAsync$typeArg(()=> $constructBody");
      } else {
        writeln("g.registerSingleton$typeArg($constructBody");
      }
    }
    if (dep.signalsReady != null) {
      write(',signalsReady: ${dep.signalsReady}');
    }
    if (dep.instanceName != null) {
      write(",instanceName: '${dep.instanceName}'");
    }
    write(");");
    return buffer.toString();
  }
}
