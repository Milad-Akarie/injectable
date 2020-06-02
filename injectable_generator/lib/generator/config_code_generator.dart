import 'dart:async';

import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/factory_param_generator.dart';
import 'package:injectable_generator/generator/module_factory_generator.dart';
import 'package:injectable_generator/generator/singleton_generator.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/utils.dart';

import 'lazy_factory_generator.dart';

// holds all used var names
// to make sure we don't have duplicate var names
// in the register function
final Set<String> registeredVarNames = {};

class ConfigCodeGenerator {
  final List<DependencyConfig> allDeps;
  final _buffer = StringBuffer();

  ConfigCodeGenerator(this.allDeps);

  _write(Object o) => _buffer.write(o);

  _writeln(Object o) => _buffer.writeln(o);

  // generate configuration function from dependency configs
  FutureOr<String> generate() async {
    // clear previously registered var names
    registeredVarNames.clear();

    // sort dependencies alphabetically
    allDeps.sort((a, b) => a.type.compareTo(b.type));

    // sort dependencies by their register order
    final Set<DependencyConfig> sorted = {};
    _sortByDependents(allDeps.toSet(), sorted);

    final modules =
        sorted.where((d) => d.isFromModule).map((d) => d.moduleName).toSet();

    final Set<DependencyConfig> eagerDeps = sorted
        .where((d) => d.injectableType == InjectableType.singleton)
        .toSet();

    final lazyDeps = sorted.difference(eagerDeps);

    // generate import
    final imports = sorted.fold<Set<String>>(
        {}, (a, b) => a..addAll(b.imports.where((i) => i != null)));

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
      final envDeps = sorted.where((dep) => dep.environment == env).toSet();
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
          _writeln(SingletonGenerator().generate(dep));
        } else {
          if (dep.environment != currentEnv) {
            _writeln("if(environment == '${dep.environment}'){");
          }
          _writeln(SingletonGenerator().generate(dep));
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
    deps.forEach((dep) {
      if (dep.injectableType == InjectableType.factory) {
        if (dep.dependencies.any((d) => d.isFactoryParam)) {
          _writeln(FactoryParamGenerator().generate(dep));
        } else {
          _writeln(LazyFactoryGenerator().generate(dep));
        }
      } else if (dep.injectableType == InjectableType.lazySingleton) {
        _writeln(LazyFactoryGenerator(isLazySingleton: true).generate(dep));
      }
    });
  }

  void _sortByDependents(
      Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
    for (var dep in unSorted) {
      if (dep.dependencies.every(
        (iDep) =>
            iDep.isFactoryParam ||
            sorted.map((d) => d.type).contains(iDep.type) ||
            !unSorted.map((d) => d.type).contains(iDep.type),
      )) {
        sorted.add(dep);
      }
    }
    if (unSorted.isNotEmpty) {
      _sortByDependents(unSorted.difference(sorted), sorted);
    }
  }

  bool _hasAsync(Set<DependencyConfig> deps) {
    return deps.any((d) => d.isAsync && d.preResolve);
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
    return deps
        .where((d) => d.isFromModule && d.moduleName == m && d.isAbstract);
  }

  void _generateModuleItems(List<DependencyConfig> moduleDeps) {
    moduleDeps.forEach((d) {
      _writeln('@override');
      _writeln(ModuleFactoryGenerator().generate(d));
    });
  }
}
