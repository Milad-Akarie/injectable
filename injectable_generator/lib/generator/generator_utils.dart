import '../dependency_config.dart';

class GeneratorUtils {
  const GeneratorUtils._();

  static void sortByDependents(Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
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

  static bool hasPreResolvedDeps(Set<DependencyConfig> deps) {
    return deps.any((d) => d.isAsync && d.preResolve);
  }
}
