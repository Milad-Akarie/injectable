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

    final Set<DependencyConfig> eagerDeps = sorted
        .where((d) => d.injectableType == InjectableType.singleton)
        .toSet();

    final lazyDeps = sorted.difference(eagerDeps);

    // generate import
    final imports =
        sorted.fold<Set<String>>({}, (a, b) => a..addAll(b.allImports));

    // add getIt import statement
    imports.add("package:get_it/get_it.dart");
    // generate all imports
    imports.forEach((import) => _writeln("import '$import';"));

    if (_hasAsync(sorted)) {
      _writeln(
          "Future<void> \$initGetIt(GetIt g, {String environment}) async {");
    } else {
      _writeln("void \$initGetIt(GetIt g, {String environment}) {");
    }

    // generate configuration function declaration

    // generate common registering
    _generateDeps(lazyDeps.where((dep) => dep.environment == null).toSet());

    _writeln("");

    final environmentMap = <String, Set<DependencyConfig>>{};
    lazyDeps
        .map((dep) => dep.environment)
        .toSet()
        .where((env) => env != null)
        .forEach((env) {
      _writeln("if(environment == '$env'){");
      final envDeps = sorted.where((dep) => dep.environment == env).toSet();
      environmentMap[env] = envDeps;
      _writeln(
          '${_hasAsync(envDeps) ? 'await' : ''} _register${capitalize(env)}Dependencies(g);');
      _writeln('}');
    });

    if (eagerDeps.isNotEmpty) {
      _writeln(
          '${_hasAsync(eagerDeps) ? 'await' : ''} _registerEagerSingletons(g,environment);');
    }

    _write('}');

    // generate environment registering
    environmentMap.forEach((env, deps) {
      if (_hasAsync(deps)) {
        _writeln(
            "Future<void> _register${capitalize(env)}Dependencies(GetIt g) async {");
      } else {
        _writeln("void _register${capitalize(env)}Dependencies(GetIt g){");
      }
      _generateDeps(deps);
      _writeln("}");
    });

    if (eagerDeps.isNotEmpty) {
      var currentEnv;
      final eagerList = eagerDeps.toList();
      _writeln("\n\n// Eager singletons must be registered in the right order");

      if (_hasAsync(eagerDeps)) {
        _writeln(
            "Future<void> _registerEagerSingletons(GetIt g,String environment) async {");
      } else {
        _writeln("void _registerEagerSingletons(GetIt g,String environment) {");
      }

      for (int i = 0; i < eagerList.length; i++) {
        final dep = eagerList[i];
        if (dep.environment == null) {
          _generateRegisterFunction(dep);
        } else {
          if (dep.environment != currentEnv) {
            _writeln("if(environment == '${dep.environment}'){");
          }
          _generateRegisterFunction(dep);
          if (i == eagerList.length - 1 ||
              eagerList[i + 1].environment != dep.environment) {
            _writeln('}');
          }
        }
        currentEnv = dep.environment;
      }

      _writeln("}");
    }

    return _buffer.toString();
  }

  void _generateDeps(Set<DependencyConfig> deps) {
    deps.forEach((dep) => _generateRegisterFunction(dep));
  }

  void _sortByDependents(
      Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
    for (var dep in unSorted) {
      if (dep.dependencies.every(
        (idep) =>
            sorted.map((d) => d.type).contains(idep.type) ||
            !unSorted.map((d) => d.type).contains(idep.type),
      )) {
        sorted.add(dep);
      }
    }
    if (unSorted.isNotEmpty) {
      _sortByDependents(unSorted.difference(sorted), sorted);
    }
  }

  void _generateRegisterFunction(DependencyConfig dep) {
    String registerFunc;
    String constructBody;

    if (dep.initializer != null) {
      final init = dep.initializer;
      if (init.isAsync) {
        final awaitedVar = toCamelCase(dep.type);
        _writeln('final $awaitedVar = await ${init.code} ;');
        constructBody = awaitedVar;
      } else {
        constructBody = init.code;
      }
    } else {
      constructBody = _generateConstructor(dep);
    }

    if (dep.injectableType == InjectableType.singleton) {
      registerFunc = constructBody;
    } else {
      registerFunc = '=> $constructBody';
    }

    final typeArg = '<${dep.type}>';
    if (dep.injectableType == InjectableType.factory) {
      _writeln("g.registerFactory$typeArg(() $registerFunc");
    } else if (dep.injectableType == InjectableType.lazySingleton) {
      _writeln("g.registerLazySingleton$typeArg(() $registerFunc");
    } else {
      _writeln("g.registerSingleton$typeArg($registerFunc");
    }

    if (dep.instanceName != null) {
      _write(",instanceName: '${dep.instanceName}'");
    }
    if (dep.signalsReady != null) {
      _write(',signalsReady: ${dep.signalsReady}');
    }
    _write(");");
  }

  String _generateConstructor(DependencyConfig dep) {
    final constBuffer = StringBuffer();
    dep.dependencies.asMap().forEach((i, injectedDep) {
      String type = '<${injectedDep.type}>';
      String instanceName = '';
      if (injectedDep.name != null) {
        type = '';
        instanceName = "'${injectedDep.name}'";
      }
      final paramName =
          (injectedDep.paramName != null) ? '${injectedDep.paramName}:' : '';
      constBuffer.write("${paramName}g$type($instanceName),");
    });

    final constructName =
        dep.constructorName.isEmpty ? "" : ".${dep.constructorName}";
    return '${dep.bindTo}$constructName(${constBuffer.toString()})';
  }

  bool _hasAsync(Set<DependencyConfig> deps) {
    return deps.any((d) => d.initializer?.isAsync == true);
  }
}
