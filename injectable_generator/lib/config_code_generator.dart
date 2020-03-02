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

    final modules = sorted
        .where((d) => d.moduleConfig != null)
        .map((d) => d.moduleConfig.moduleName)
        .toSet();

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

    modules.forEach((m) {
      final constParam = _getAbstractModuleDeps(sorted, m)
              .any((d) => d.dependencies.isNotEmpty)
          ? 'g'
          : '';
      _writeln('final ${toCamelCase(m)} = _\$$m($constParam);');
    });

    // generate common registering
    _generateDeps(lazyDeps.where((dep) => dep.environment == null).toSet());

    _writeln("");

    lazyDeps
        .map((dep) => dep.environment)
        .toSet()
        .where((env) => env != null)
        .forEach((env) {
      _writeln('\n\n  //Register $env Dependencies --------');
      _writeln("if(environment == '$env'){");
      final envDeps = lazyDeps.where((dep) => dep.environment == env).toSet();
      _generateDeps(envDeps);
      _writeln('}');
    });

    if (eagerDeps.isNotEmpty) {
      _writeln(
          "\n\n  //Eager singletons must be registered in the right order");

      var currentEnv;
      final eagerList = eagerDeps.toList();

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
    }

    _write('}');

    _generateModules(modules, sorted);

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

    if (dep.moduleConfig != null) {
      final mConfig = dep.moduleConfig;
      final mName = toCamelCase(mConfig.moduleName);
      if (mConfig.isAsync) {
        final awaitedVar = toCamelCase(dep.type);
        _writeln('final $awaitedVar = await $mName.${mConfig.name};');
        constructBody = awaitedVar;
      } else {
        constructBody = '$mName.${mConfig.name}';
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

  String _generateConstructor(DependencyConfig dep, {String getIt = 'g'}) {
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
    final strippedClassName = RegExp('^([^<]*)').stringMatch(dep.bindTo);
    return '${strippedClassName}$constructName(${constBuffer.toString()})';
  }

  bool _hasAsync(Set<DependencyConfig> deps) {
    return deps.any((d) => d.moduleConfig?.isAsync == true);
  }

  void _generateModules(Set<String> modules, Set<DependencyConfig> deps) {
    modules.forEach((m) {
      _writeln('class _\$$m extends $m{');
      final moduleDeps = _getAbstractModuleDeps(deps, m).toList();
      if (moduleDeps.any((d) => d.dependencies.isNotEmpty)) {
        _writeln("final GetIt _g;");
        _writeln('_\$$m(this._g);');
      }
      _generateModuleItems(moduleDeps);
      _writeln('}');
    });
  }

  Iterable<DependencyConfig> _getAbstractModuleDeps(
      Set<DependencyConfig> deps, String m) {
    return deps.where((d) =>
        d.moduleConfig != null &&
        d.moduleConfig.moduleName == m &&
        d.moduleConfig.isAbstract);
  }

  void _generateModuleItems(List<DependencyConfig> moduleDeps) {
    moduleDeps.forEach((d) {
      _writeln('@override');
      final constructor = _generateConstructor(d, getIt: '_g');
      _writeln('${d.bindTo} get ${d.moduleConfig.name} => $constructor ;');
    });
  }
}
