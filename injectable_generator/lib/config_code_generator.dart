import 'dart:async';

import 'package:injectable_generator/src/dependency_config.dart';
import 'package:injectable_generator/utils.dart';

import 'injectable_types.dart';

class ConfigCodeGenerator {
  final List<DependencyConfig> deps;
  final _buffer = StringBuffer();
  ConfigCodeGenerator(this.deps);

  _write(Object o) => _buffer.write(o);
  _writeln(Object o) => _buffer.writeln(o);

  // generate configuration function from dependency configs
  FutureOr<String> generate() async {
    // generate import
    final imports =
        deps.fold<Set<String>>({}, (all, d) => all..addAll(d.allImports));

    // add getIt import statement
    imports.add("package:get_it/get_it.dart");
    // generate all imports
    imports.forEach((import) => _writeln("import '$import';"));

    // generate configuration function declaration
    _writeln("void initGetIt(GetIt getIt,{String environment}) {");

    // generate common registering
    _generateDeps(deps.where((dep) => dep.environment == null).toList());

    _writeln("");

    final environmentMap = <String, List<DependencyConfig>>{};

    deps
        .map((dep) => dep.environment)
        .toSet()
        .where((env) => env != null)
        .forEach((env) {
      _writeln("if(environment == '$env'){");
      _writeln('_register${capitalize(env)}Dependencies(getIt);');
      environmentMap[env] =
          deps.where((dep) => dep.environment == env).toList();
      _writeln('}');
    });

    _write('}');

    // generate environment registering
    environmentMap.forEach((env, deps) {
      _write("void _register${capitalize(env)}Dependencies(GetIt getIt){");
      _generateDeps(deps);
      _writeln("}");
    });
    return _buffer.toString();
  }

  void _generateDeps(List<DependencyConfig> deps) {
    _write('getIt');
    deps.forEach((dep) {
      final constBuffer = StringBuffer();
      dep.dependencies.asMap().forEach((i, injectedDep) {
        final comma =
            (i < dep.dependencies.length - 1 || dep.dependencies.length > 2)
                ? ','
                : '';

        String type = '<${injectedDep.type}>';
        String instanceName = '';
        if (injectedDep.name != null) {
          type = '';
          instanceName = "'${injectedDep.name}'";
        }
        constBuffer.write("getIt$type($instanceName)$comma");
      });

      final typeArg = dep.bindTo != null ? '<${dep.bindTo}>' : '';

      final construct = '${dep.type}(${constBuffer.toString()}';

      if (dep.injectableType == InjectableType.factory) {
        _writeln("..registerFactory$typeArg(()=> $construct)");
      } else if (dep.injectableType == InjectableType.singleton) {
        _writeln("..registerSingleton$typeArg($construct)");
      } else {
        _writeln("..registerLazySingleton$typeArg(()=> $construct)");
      }

      if (dep.instanceName != null) {
        _write(",instanceName: '${dep.instanceName}'");
      }
      if (dep.signalsReady != null) {
        _write(',signalsReady: ${dep.signalsReady}');
      }
      _write(")");
    });
    _write(';');
  }
}
