import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/register_func_generator.dart';

class LazyFactoryGenerator extends RegisterFuncGenerator {
  final isLazySingleton;
  final String funcName;

  LazyFactoryGenerator(Set<ImportableType> prefixedTypes,
      {this.isLazySingleton = false})
      : funcName = isLazySingleton ? 'lazySingleton' : 'factory',
        super(prefixedTypes);

  @override
  String generate(DependencyConfig dep) {
    final initializer = generateInitializer(dep);

    var constructor = initializer;
    if (dep.registerAsInstance) {
      constructor = generateAwaitSetup(dep, initializer);
    }

    final asyncStr = dep.isAsync && !dep.preResolve ? 'Async' : '';

    write(
        "gh.$funcName$asyncStr<${dep.type.getDisplayName(prefixedTypes)}>(()=> $constructor");

    closeRegisterFunc(dep);
    return buffer.toString();
  }
}
