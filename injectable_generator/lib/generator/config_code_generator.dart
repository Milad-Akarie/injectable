import 'dart:async';

import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/singleton_generator.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/utils.dart';

import 'factory_generator.dart';

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
    _generateDeps(sorted.where((dep) => dep.environment == null).toSet());

    _writeln("");

    sorted
        .map((dep) => dep.environment)
        .toSet()
        .where((env) => env != null)
        .forEach((env) {
      _writeln('\n\n  //Register $env Dependencies --------');
      _writeln("if(environment == '$env'){");
      final envDeps = sorted.where((dep) => dep.environment == env).toSet();
      _generateDeps(envDeps);
      _writeln('}');
    });

    _write('}');

    _generateModules(modules, sorted);

    return _buffer.toString();
  }

  void _generateDeps(Set<DependencyConfig> deps) {
    deps.forEach((dep) {
      if (dep.injectableType == InjectableType.factory) {
        _writeln(LazyFactoryGenerator().generate(dep));
      } else if (dep.injectableType == InjectableType.lazySingleton) {
        _writeln(LazySingletonGenerator().generate(dep));
      } else if (dep.injectableType == InjectableType.singleton) {
        _writeln(SingletonGenerator().generate(dep));
      }
      // _generateRegisterFunction(dep);
    });
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
      if (dep.isAsync && dep.asInstance) {
        final awaitedVar = toCamelCase(stripGenericTypes(dep.type));
        _writeln('final $awaitedVar = await $mName.${mConfig.name};');
        constructBody = awaitedVar;
      } else {
        constructBody = '$mName.${mConfig.name}';
      }
    } else {
      constructBody = _generateConstructor(dep);
    }

    if (dep.injectableType == InjectableType.singleton &&
        dep.dependencies.isEmpty &&
        dep.asInstance) {
      registerFunc = constructBody;
    } else {
      registerFunc = '=> $constructBody';
    }

    final typeArg = '<${dep.type}>';
    final asyncStr = dep.isAsync && !dep.asInstance ? 'Async' : '';
    if (dep.injectableType == InjectableType.factory) {
      _writeln("g.registerFactory$asyncStr$typeArg(() $registerFunc");
    } else if (dep.injectableType == InjectableType.lazySingleton) {
      _writeln("g.registerLazySingleton$asyncStr$typeArg(() $registerFunc");
    } else {
      if (dep.dependencies.isNotEmpty) {
        final suffix = dep.isAsync ? 'Async' : 'WithDependencies';
        final dependsOn =
            dep.dependencies.map((d) => stripGenericTypes(d.type)).toList();
        _writeln(
            "g.registerSingleton$suffix$typeArg(()$registerFunc, dependsOn:$dependsOn");
      } else {
        if (dep.isAsync && !dep.asInstance) {
          _writeln("g.registerSingletonAsync$typeArg(()$registerFunc");
        } else {
          _writeln("g.registerSingleton$typeArg($registerFunc");
        }
      }
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
    return '${stripGenericTypes(dep.bindTo)}$constructName(${constBuffer.toString()})';
  }

  bool _hasAsync(Set<DependencyConfig> deps) {
    return deps.any((d) => d.isAsync && d.asInstance);
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
