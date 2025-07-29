import 'dart:collection';

import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:meta/meta.dart';

class DependencyList with IterableMixin<DependencyConfig> {
  final List<DependencyConfig> _dependencies;

  DependencyList({
    required List<DependencyConfig> dependencies,
  }) : _dependencies = sortDependencies(dependencies);

  bool hasAsyncDependency(DependencyConfig dep) {
    _ensureAsyncDepsMapInitialized();
    return _hasAsyncDeps![dep.id] ?? false;
  }

  bool isAsyncOrHasAsyncDependency(InjectedDependency iDep) {
    _ensureAsyncDepsMapInitialized();
    return _isAsyncOrHasAsyncDeps![iDep.id] ?? false;
  }

  Map<_DependencyId, bool>? _hasAsyncDeps;
  Map<_DependencyId, bool>? _isAsyncOrHasAsyncDeps;

  void _ensureAsyncDepsMapInitialized() {
    if (_hasAsyncDeps != null) {
      return;
    }

    final hasAsyncDepsMap = <_DependencyId, bool>{};
    final isAsyncOrHasAsyncDepsMap = <_DependencyId, bool>{};

    for (final dep in _dependencies) {
      final hasAsyncDeps = dep.dependencies.any((childDependency) {
        final cid = childDependency.id;
        return isAsyncOrHasAsyncDepsMap[cid] ?? false;
      });

      final did = dep.id;
      hasAsyncDepsMap[did] = hasAsyncDeps;
      isAsyncOrHasAsyncDepsMap[did] =
          (dep.isAsync && !dep.preResolve) || hasAsyncDeps;
    }

    _hasAsyncDeps = hasAsyncDepsMap;
    _isAsyncOrHasAsyncDeps = isAsyncOrHasAsyncDepsMap;
  }

  @override
  Iterator<DependencyConfig> get iterator => _dependencies.iterator;
}

class _DependencyId {
  final ImportableType type;
  final String? instanceName;

  const _DependencyId({
    required this.type,
    required this.instanceName,
  });

  @override
  String toString() {
    return 'DependencyId{type: $type, instanceName: $instanceName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _DependencyId &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          instanceName == other.instanceName);

  @override
  int get hashCode => Object.hash(type, instanceName);
}

extension _DependencyConfigX on DependencyConfig {
  _DependencyId get id => _DependencyId(type: type, instanceName: instanceName);
}

extension _InjectedDependencyX on InjectedDependency {
  _DependencyId get id => _DependencyId(type: type, instanceName: instanceName);
}

@visibleForTesting
List<DependencyConfig> sortDependencies(List<DependencyConfig> it) {
  // sort dependencies alphabetically by all the various attributes that may make them unique
  final deps = it.sortedBy<num>((e) => e.identityHash);
  // sort dependencies by their register order
  final List<DependencyConfig> sorted = [];
  _sortByDependents(deps, sorted);
  // sort dependencies by their orderPosition
  return sorted.sortedBy<num>((e) => e.orderPosition);
}

void _sortByDependents(
    List<DependencyConfig> unSorted, List<DependencyConfig> sorted) {
  for (var dep in unSorted) {
    if (dep.dependencies.every(
      (iDep) {
        if (iDep.isFactoryParam) {
          return true;
        }

        /// for empty environments we check to see if all the dependencies from
        /// all the environments are already in sorted
        if (dep.environments.isEmpty) {
          final List<DependencyConfig> deps = unSorted
              .where((d) =>
          d.type == iDep.type && d.instanceName == iDep.instanceName)
              .toList(growable: false);

          if (deps.every(sorted.contains)) {
            return true;
          }
        } else if (lookupDependencyWithNoEnvOrHasAny(
            iDep, sorted, dep.environments) !=
            null) {
          // if dep is already in sorted return true
          return true;
        }

        // if dep is in unSorted we skip it in this iteration, if not we include it
        return lookupDependencyWithNoEnvOrHasAny(
                iDep, unSorted, dep.environments) ==
            null;
      },
    )) {
      sorted.add(dep);
    }
  }
  if (unSorted.isNotEmpty) {
    var difference =
        unSorted.where((element) => !sorted.contains(element)).toList();

    _sortByDependents(difference, sorted);
  }
}

DependencyConfig? lookupDependency(
    InjectedDependency iDep, List<DependencyConfig> allDeps) {
  return allDeps.firstWhereOrNull(
    (d) => d.type == iDep.type && d.instanceName == iDep.instanceName,
  );
}

DependencyConfig? lookupDependencyWithNoEnvOrHasAny(
  InjectedDependency iDep,
  List<DependencyConfig> allDeps,
  List<String> envs,
) {
  return allDeps.firstWhereOrNull(
    (d) =>
        d.type == iDep.type &&
        d.instanceName == iDep.instanceName &&
        (d.environments.isEmpty ||
            envs.isEmpty ||
            d.environments.any(
              (e) => envs.contains(e),
            )),
  );
}

Set<DependencyConfig> lookupPossibleDeps(
    InjectedDependency iDep, Iterable<DependencyConfig> allDeps) {
  return allDeps
      .where((d) => d.type == iDep.type && d.instanceName == iDep.instanceName)
      .toSet();
}

bool hasPreResolvedDependencies(Iterable<DependencyConfig> deps) {
  return deps.any((d) => d.isAsync && d.preResolve);
}

TypeReference nullableRefer(
  String symbol, {
  String? url,
  bool nullable = false,
}) =>
    TypeReference((b) => b
      ..symbol = symbol
      ..url = url
      ..isNullable = nullable);

Reference typeRefer(ImportableType type,
    [Uri? targetFile, bool withNullabilitySuffix = true]) {
  final import = targetFile == null
      ? ImportableTypeResolver.resolveAssetImport(type.import)
      : ImportableTypeResolver.relative(type.import, targetFile);

  if (type.isRecordType) {
    return RecordType(
      (b) => b
        ..url = import
        ..isNullable = type.isNullable
        ..positionalFieldTypes.addAll(
          type.typeArguments.where((e) => !e.isNamedRecordField).map(typeRefer),
        )
        ..namedFieldTypes.addAll({
          for (final entry in [
            ...type.typeArguments.where((e) => e.isNamedRecordField)
          ])
            entry.nameInRecord!: typeRefer(entry)
        }),
    );
  }

  return TypeReference((reference) {
    reference
      ..symbol = type.name
      ..url = import
      ..isNullable = withNullabilitySuffix && type.isNullable;
    if (type.typeArguments.isNotEmpty) {
      reference.types.addAll(
        type.typeArguments.map((e) => typeRefer(e, targetFile)),
      );
    }
  });
}
