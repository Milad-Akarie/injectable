import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';

Set<DependencyConfig> sortDependencies(List<DependencyConfig> deps) {
  // sort dependencies alphabetically
  deps.sort((a, b) => a.type.name.compareTo(b.type.name));
  // sort dependencies by their register order
  final Set<DependencyConfig> sorted = {};
  _sortByDependents(deps.toSet(), sorted);
  // sort dependencies by their orderPosition
  final orderSorted = sorted.toList()..sort(_sortDependencyConfigByOrder);
  return orderSorted.toSet();
}

int _sortDependencyConfigByOrder(
  DependencyConfig current,
  DependencyConfig next,
) {
  if (next.orderPosition == current.orderPosition) return 0;
  return next.orderPosition > current.orderPosition ? -1 : 1;
}

void _sortByDependents(
    Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
  for (var dep in unSorted) {
    if (dep.dependencies.every(
      (iDep) {
        if (iDep.isFactoryParam) {
          return true;
        }
        // if dep is already in sorted return true
        if (lookupDependencyWithNoEnvOrHasAny(iDep, sorted, dep.environments) !=
            null) {
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
    _sortByDependents(unSorted.difference(sorted), sorted);
  }
}

bool isAsyncOrHasAsyncDependency(
    InjectedDependency iDep, Set<DependencyConfig> allDeps) {
  final dep = lookupDependency(iDep, allDeps);
  if (dep == null) {
    return false;
  }

  if (dep.isAsync && !dep.preResolve) {
    return true;
  }

  return hasAsyncDependency(dep, allDeps);
}

bool hasAsyncDependency(DependencyConfig dep, Set<DependencyConfig> allDeps) {
  for (final iDep in dep.dependencies) {
    var config = lookupDependency(iDep, allDeps);

    // If the dependency corresponding to the InjectedDependency couldn't be
    // found, this probably indicates there is a missing dependency.
    if (config == null) {
      continue;
    }

    // Ultimately, this is what we're looking for:
    if (config.isAsync && !config.preResolve) {
      return true;
    }

    // If the dependency itself isn't async, check to see if any of *its*
    // dependencies are async.
    if (hasAsyncDependency(config, allDeps)) {
      return true;
    }
  }
  return false;
}

DependencyConfig? lookupDependency(
    InjectedDependency iDep, Set<DependencyConfig> allDeps) {
  return allDeps.firstWhereOrNull(
    (d) => d.type == iDep.type && d.instanceName == iDep.instanceName,
  );
}

DependencyConfig? lookupDependencyWithNoEnvOrHasAny(
  InjectedDependency iDep,
  Set<DependencyConfig> allDeps,
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

bool hasPreResolvedDependencies(Set<DependencyConfig> deps) {
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
  final relativeImport = targetFile == null
      ? ImportableTypeResolver.resolveAssetImport(type.import)
      : ImportableTypeResolver.relative(type.import, targetFile);
  return TypeReference((reference) {
    reference
      ..symbol = type.name
      ..url = relativeImport
      ..isNullable = withNullabilitySuffix && type.isNullable;
    if (type.typeArguments.isNotEmpty) {
      reference.types.addAll(
        type.typeArguments.map((e) => typeRefer(e, targetFile)),
      );
    }
  });
}
