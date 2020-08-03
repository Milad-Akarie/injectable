import 'dart:async';

import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/factory_param_generator.dart';
import 'package:injectable_generator/generator/module_factory_generator.dart';
import 'package:injectable_generator/generator/singleton_generator.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/utils.dart';

import '../importable_type_resolver.dart';
import 'lazy_factory_generator.dart';

/// holds all used var names
/// to make sure we don't have duplicate var names
/// in the register function
final Set<String> registeredVarNames = {};

class ConfigCodeGenerator {
  final List<DependencyConfig> allDeps;
  final Set<ImportableType> prefixedTypes = {};
  final _buffer = StringBuffer();
  final Uri targetFile;

  ConfigCodeGenerator(this.allDeps, {this.targetFile});

  _write(Object o) => _buffer.write(o);

  _writeln(Object o) => _buffer.writeln(o);

  // generate configuration function from dependency configs
  FutureOr<String> generate() async {
    // clear previously registered var names
    registeredVarNames.clear();
    var importsWithPrefixes = _addRequiredPrefixes(allDeps);

    prefixedTypes.addAll(importsWithPrefixes.where((e) => e.prefix != null));
    _generateImports(importsWithPrefixes);

    // sort dependencies alphabetically
    allDeps.sort((a, b) => a.type.name.compareTo(b.type.name));

    // sort dependencies by their register order
    final Set<DependencyConfig> sorted = {};
    _sortByDependents(allDeps.toSet(), sorted);

    final modules = sorted.where((d) => d.isFromModule).map((d) => d.module).toSet();

    final environments = sorted.fold(<String>{}, (prev, elm) => prev..addAll(elm.environments));
    if (environments.isNotEmpty) {
      _writeln("/// Environment names");
      environments.forEach((env) => _writeln("const _$env = '$env';"));
    }
    final eagerDeps = sorted.where((d) => d.injectableType == InjectableType.singleton).toSet();

    final lazyDeps = sorted.difference(eagerDeps);

    _writeln('''
      /// adds generated dependencies 
      /// to the provided [GetIt] instance
   ''');

    if (_hasAsync(sorted)) {
      _writeln("Future<void> \$initGetIt(GetIt g, {String environment, bool Function(Set<String>) environmentFilter}) async {");
    } else {
      _writeln("void \$initGetIt(GetIt g, {String environment, bool Function(Set<String>) environmentFilter}) {");
    }
    _writeln("final gh = GetItHelper(g, environment, environmentFilter);");
    modules.forEach((m) {
      final constParam = _getAbstractModuleDeps(sorted, m)
          .any((d) => d.dependencies.isNotEmpty)
          ? 'g'
          : '';
      _writeln('final ${toCamelCase(m.name)} = _\$$m($constParam);');
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

  Set<ImportableType> _addRequiredPrefixes(Iterable<DependencyConfig> deps) {
    final importableTypes = deps.fold<List<ImportableType>>(
        [], (a, b) => a..addAll(b.allImportableTypes));
    // add getIt import statement
    importableTypes.add(ImportableType(
      name: 'GetIt',
      import: 'package:get_it/get_it.dart',
    ));
    importableTypes.add(
      ImportableType(
        name: 'GetItHelper',
        import: 'package:injectable/get_it_helper.dart',
      ),
    );

    return ImportableTypeResolver.resolvePrefixes(importableTypes.toSet());
  }

  void _generateImports(Set<ImportableType> imports) {
    // prevent duplicated imports
    var uniqueImports = <ImportableType>{};
    imports.forEach((iType) {
      if (uniqueImports
          .where((e) => iType.import == e.import)
          .isEmpty) {
        uniqueImports.add(iType);
      }
    });

    var finalizedImports = (targetFile == null
        ? uniqueImports.map((e) =>
        e.copyWith(
            import: ImportableTypeResolver.resolveAssetImports(e.import)))
        : uniqueImports.map((e) =>
        e.copyWith(
            import: ImportableTypeResolver.relative(e.import, targetFile))))
        .toSet();

    var dartImports =
    finalizedImports.where((e) => e.import.startsWith('dart')).toList();
    if (dartImports.isNotEmpty) {
      _sortAndGenerate(dartImports);
      _writeln("");
    }

    var packageImports =
    finalizedImports.where((e) => e.import.startsWith('package')).toList();
    if (packageImports.isNotEmpty) {
      _sortAndGenerate(packageImports);
      _writeln("");
    }

    var rest = finalizedImports
        .difference({...dartImports, ...packageImports}).toList();
    _sortAndGenerate(rest);
  }

  void _sortAndGenerate(List<ImportableType> importableTypes) {
    importableTypes.sort((a, b) => a.name.compareTo(b.name));
    importableTypes.forEach((IType) => _writeln("import ${IType.importName};"));
  }

  void _generateDeps(Iterable<DependencyConfig> deps) {
    deps.forEach((dep) {
      if (dep.injectableType == InjectableType.factory) {
        if (dep.dependencies.any((d) => d.isFactoryParam)) {
          _writeln(FactoryParamGenerator(prefixedTypes).generate(dep));
        } else {
          _writeln(LazyFactoryGenerator(prefixedTypes).generate(dep));
        }
      } else if (dep.injectableType == InjectableType.lazySingleton) {
        _writeln(LazyFactoryGenerator(prefixedTypes, isLazySingleton: true)
            .generate(dep));
      } else if (dep.injectableType == InjectableType.singleton) {
        _writeln(SingletonGenerator(prefixedTypes).generate(dep));
      }
    });
  }

  void _sortByDependents(Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
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

  void _generateModules(Set<ImportableType> modules, Set<DependencyConfig> deps) {
    modules.forEach((m) {
      _writeln('class _\$$m extends ${m.getDisplayName(prefixedTypes)}{');
      final moduleDeps = _getAbstractModuleDeps(deps, m).toList();
      if (moduleDeps.any((d) => d.dependencies.isNotEmpty)) {
        _writeln("final GetIt _g;");
        _writeln('_\$$m(this._g);');
      }
      _generateModuleItems(moduleDeps);
      _writeln('}');
    });
  }

  Iterable<DependencyConfig> _getAbstractModuleDeps(Set<DependencyConfig> deps, ImportableType m) {
    return deps.where((d) => d.isFromModule && d.module == m && d.isAbstract);
  }

  void _generateModuleItems(List<DependencyConfig> moduleDeps) {
    moduleDeps.forEach((d) {
      _writeln('@override');
      _writeln(ModuleFactoryGenerator(prefixedTypes).generate(d));
    });
  }
}
