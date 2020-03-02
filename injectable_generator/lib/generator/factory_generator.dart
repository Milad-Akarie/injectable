import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class LazyFactoryGenerator extends RegisterFuncGenerator {
  @override
  String generate(DependencyConfig dep) {
    final constructBody = dep.moduleConfig == null
        ? generateConstructor(dep)
        : generateConstructorForModule(dep);

    final asyncStr = dep.isAsync && !dep.asInstance ? 'Async' : '';
    writeln("g.registerFactory$asyncStr<${dep.type}>(()=> $constructBody");
    if (dep.instanceName != null) {
      write(",instanceName: '${dep.instanceName}'");
    }
    write(");");
    return buffer.toString();
  }
}

class LazySingletonGenerator extends LazyFactoryGenerator {
  @override
  String generate(DependencyConfig dep) {
    final constructBody = dep.moduleConfig == null
        ? generateConstructor(dep)
        : generateConstructorForModule(dep);

    final asyncStr = dep.isAsync && !dep.asInstance ? 'Async' : '';
    writeln(
        "g.registerLazySingleton$asyncStr<${dep.type}>(()=> $constructBody");

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
