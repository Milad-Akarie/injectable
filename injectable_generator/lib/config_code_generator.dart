import 'dart:async';

import 'package:injectable_generator/utils.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

class ConfigCodeGenerator {
  final List<DependencyConfig> allDeps;
  final _buffer = StringBuffer();

  ConfigCodeGenerator(this.allDeps);

  _write(Object o) => _buffer.write(o);
  _writeln(Object o) => _buffer.writeln(o);

  // generate configuration function from dependency configs
  FutureOr<String> generate() async {
    // sort dependencies by their register order
    final Set<DependencyConfig> sorted = {};
    _sortByDependents(allDeps.toSet(), sorted);
    // generate import
    final imports = sorted.fold<Set<String>>({}, (a, b) => a..addAll(b.allImports));

    // add getIt import statement
    imports.add("package:get_it/get_it.dart");
    // generate all imports
    imports.forEach((import) => _writeln("import '$import';"));

    // generate configuration function declaration
    _writeln("void \$initGetIt(GetIt getIt, {String environment}) {");

    // generate common registering
    _generateDeps(sorted.where((dep) => dep.environment == null).toList());

    _writeln("");

    final environmentMap = <String, List<DependencyConfig>>{};
    sorted.map((dep) => dep.environment).toSet().where((env) => env != null).forEach((env) {
      _writeln("if(environment == '$env'){");
      _writeln('_register${capitalize(env)}Dependencies(getIt);');
      environmentMap[env] = sorted.where((dep) => dep.environment == env).toList();
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
    if (deps.isEmpty) {
      return;
    }

    _write('getIt');
    deps.forEach((dep) {
      final constBuffer = StringBuffer();
      dep.dependencies.asMap().forEach((i, injectedDep) {
        final comma = (i < dep.dependencies.length - 1 || dep.dependencies.length > 2) ? ',' : '';

        String type = '<${injectedDep.type}>';
        String instanceName = '';
        if (injectedDep.name != null) {
          type = '';
          instanceName = "'${injectedDep.name}'";
        }
        final paramName = (injectedDep.paramName != null) ? '${injectedDep.paramName}:' : '';
        constBuffer.write("${paramName}getIt$type($instanceName)$comma");
      });

      final typeArg = '<${dep.type}>';
      final constructName = dep.constructorName.isEmpty ? "" : ".${dep.constructorName}";
      final construct = '${dep.bindTo}$constructName(${constBuffer.toString()}';

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

  void _sortByDependents(Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
    for (var dep in unSorted) {
      if (dep.dependencies.every(
        (idep) => sorted.map((d) => d.type).contains(idep.type) || !unSorted.map((d) => d.type).contains(idep.type),
      )) {
        sorted.add(dep);
      }
    }
    if (unSorted.isNotEmpty) {
      _sortByDependents(unSorted.difference(sorted), sorted);
    }
  }
}
