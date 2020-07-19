import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class LazyFactoryGenerator extends RegisterFuncGenerator {
  final isLazySingleton;
  final String funcName;

  LazyFactoryGenerator({this.isLazySingleton = false}) : funcName = isLazySingleton ? 'lazySingleton' : 'factory';

  @override
  String generate(DependencyConfig dep,
      {String prefix = '', String suffix = ''}) {
    final initializer = generateInitializer(dep);

    var constructor = initializer;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, initializer);
    }

    final asyncStr = dep.isAsync && !dep.preResolve ? 'Async' : '';

    write("$prefix$funcName$asyncStr<${dep.type}>(()=> $constructor");

    closeRegisterFunc(dep, suffix);
    return buffer.toString();
  }
}
