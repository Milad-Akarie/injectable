import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class LazyFactoryGenerator extends RegisterFuncGenerator {
  final isLazySingleton;
  final String funcName;

  LazyFactoryGenerator({this.isLazySingleton = false})
      : funcName =
  isLazySingleton ? 'registerLazySingleton' : 'registerFactory';

  @override
  String generate(DependencyConfig dep) {
    final initializer = generateInitializer(dep);

    var constructor = initializer;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, initializer);
    }

    final asyncStr = dep.isAsync && !dep.preResolve ? 'Async' : '';

    write("g.$funcName$asyncStr<${dep.type}>(()=> $constructor");

    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
