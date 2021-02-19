import 'package:code_builder/code_builder.dart';

import '../dependency_config.dart';

void sortByDependents(Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
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
    sortByDependents(unSorted.difference(sorted), sorted);
  }
}

bool hasPreResolvedDependencies(Set<DependencyConfig> deps) {
  return deps.any((d) => d.isAsync && d.preResolve);
}

TypeReference typeRefer(
  String symbol, {
  String url,
  bool nullable = false,
}) =>
    TypeReference((b) => b
      ..symbol = symbol
      ..url = url
      ..isNullable = nullable);
