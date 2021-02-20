import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';

Set<DependencyConfig> sortDependencies(List<DependencyConfig> deps) {
  // sort dependencies alphabetically
  deps.sort((a, b) => a.type.name.compareTo(b.type.name));

  // sort dependencies by their register order
  final Set<DependencyConfig> sorted = {};
  _sortByDependents(deps.toSet(), sorted);
  return sorted;
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

bool hasPreResolvedDependencies(Set<DependencyConfig> deps) {
  return deps.any((d) => d.isAsync && d.preResolve);
}

TypeReference nullableRefer(
  String symbol, {
  String url,
  bool nullable = false,
}) =>
    TypeReference((b) => b
      ..symbol = symbol
      ..url = url
      ..isNullable = nullable);

Reference typeRefer(ImportableType type, [Uri targetFile]) {
  final relativeImport = targetFile == null
      ? ImportableTypeResolver.resolveAssetImport(type.import)
      : ImportableTypeResolver.relative(type.import, targetFile);
  return TypeReference((b) {
    b
      ..symbol = type.name
      ..url = relativeImport
      ..isNullable = type.isNullable;
    if (type.isParametrized) {
      b.types.addAll(
        type.typeArguments?.map((e) => typeRefer(e, targetFile)),
      );
    }
    return b;
  });
}
