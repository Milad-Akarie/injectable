import 'dart:async';

import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/factory_param_generator.dart';
import 'package:injectable_generator/generator/module_factory_generator.dart';
import 'package:injectable_generator/generator/singleton_generator.dart';
import 'package:injectable_generator/import_resolver.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/utils.dart';

import 'lazy_factory_generator.dart';

/// holds all used var names
/// to make sure we don't have duplicate var names
/// in the register function
final Set<String> registeredVarNames = {};

class ConfigCodeGenerator {
  final List<DependencyConfig> allDeps;
  final _buffer = StringBuffer();
  final Uri targetFile;

  ConfigCodeGenerator(this.allDeps, {this.targetFile});

  _write(Object o) => _buffer.write(o);

  _writeln(Object o) => _buffer.writeln(o);

  // generate configuration function from dependency configs
  FutureOr<String> generate() async {
    // clear previously registered var names
    registeredVarNames.clear();
    _generateImports(allDeps);

    // sort dependencies alphabetically
    allDeps.sort((a, b) => a.type.compareTo(b.type));

    // sort dependencies by their register order
    final Set<DependencyConfig> sorted = {};
    _sortByDependents(allDeps.toSet(), sorted);

    final modules =
        sorted.where((d) => d.isFromModule).map((d) => d.moduleName).toSet();

    final environments =
        sorted.fold(<String>{}, (prev, elm) => prev..addAll(elm.environments));
    if (environments.isNotEmpty) {
      _writeln("/// Environment names");
      environments.forEach((env) => _writeln("const _$env = '$env';"));
    }
    final eagerDeps = sorted
        .where((d) => d.injectableType == InjectableType.singleton)
        .toSet();

    final lazyDeps = sorted.difference(eagerDeps);

    _writeln('''
      /// adds generated dependencies 
      /// to the provided [GetIt] instance
   ''');

    if (_hasAsync(sorted)) {
      _writeln(
          "Future<void> \$initGetIt(GetIt g, {String environment}) async {");
    } else {
      _writeln("void \$initGetIt(GetIt g, {String environment}) {");
    }
    _writeln("final gh = GetItHelper(g, environment);");
    modules.forEach((m) {
      final constParam = _getAbstractModuleDeps(sorted, m)
              .any((d) => d.dependencies.isNotEmpty)
          ? 'g'
          : '';
      _writeln('final ${toCamelCase(m)} = _\$$m($constParam);');
    });

    _generateDeps(lazyDeps);

    if (eagerDeps.isNotEmpty) {
      _writeln(
          "\n\n  // Eager singletons must be registered in the right order");
      _generateDeps(eagerDeps);
    }
    _write('}');

    _generateModules(modules, sorted);

    return _buffer.toString();
  }

  void _generateImports(Iterable<DependencyConfig> deps) {
    final imports = deps.fold<Set<String>>(
        {}, (a, b) => a..addAll(b.imports.where((i) => i != null)));

    // add getIt import statement
    imports.add("package:get_it/get_it.dart");
    imports.add("package:injectable/get_it_helper.dart");

    // generate all imports
    var resolvedImports = (targetFile == null
            ? imports.map(ImportResolver.normalizeAssetImports)
            : imports.map((e) => ImportResolver.relative(e, targetFile)))
        .toSet();

    var dartImports =
        resolvedImports.where((element) => element.startsWith('dart')).toSet();
    _sortAndGenerate(dartImports);
    _writeln("");

    var packageImports = resolvedImports
        .where((element) => element.startsWith('package'))
        .toSet();
    _sortAndGenerate(packageImports);
    _writeln("");

    var rest = resolvedImports.difference({...dartImports, ...packageImports});
    _sortAndGenerate(rest);
  }

  void _sortAndGenerate(Set<String> imports) {
    var sorted = imports.toList()..sort();
    sorted.toList().forEach((import) => _writeln("import '$import';"));
  }

  void _generateDeps(Iterable<DependencyConfig> deps) {
    deps.forEach((dep) {
      var prefix = 'gh.';
      var suffix = ';';
      if (dep.injectableType == InjectableType.factory) {
        if (dep.dependencies.any((d) => d.isFactoryParam)) {
          _writeln(FactoryParamGenerator()
              .generate(dep, prefix: prefix, suffix: suffix));
        } else {
          _writeln(LazyFactoryGenerator()
              .generate(dep, prefix: prefix, suffix: suffix));
        }
      } else if (dep.injectableType == InjectableType.lazySingleton) {
        _writeln(LazyFactoryGenerator(isLazySingleton: true)
            .generate(dep, prefix: prefix, suffix: suffix));
      } else if (dep.injectableType == InjectableType.singleton) {
        _writeln(
            SingletonGenerator().generate(dep, prefix: prefix, suffix: suffix));
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
