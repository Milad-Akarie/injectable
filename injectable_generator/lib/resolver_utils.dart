import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';

import 'code_builder/builder_utils.dart';
import 'models/dependency_config.dart';
import 'models/importable_type.dart';

void validateDuplicateDependencies(List<DependencyConfig> deps) {
  final validatedDeps = <DependencyConfig>[];
  for (var dep in deps) {
    var registered = validatedDeps.where(
      (elm) =>
          elm.type == dep.type &&
          elm.instanceName == dep.instanceName &&
          elm.scope == dep.scope,
    );

    if (registered.isEmpty) {
      validatedDeps.add(dep);
    } else {
      Set<String> registeredEnvironments = registered.fold(
        <String>{},
        (prev, elm) => prev..addAll(elm.environments),
      );

      if (registeredEnvironments.isEmpty ||
          dep.environments.any(
            (env) => registeredEnvironments.contains(env),
          )) {
        throwBoxed(
          '${dep.typeImpl} [${dep.type}] envs: ${dep.environments}  scope: ${dep.scope} \nis registered more than once under the same environment or in the same scope',
        );
      }
    }
  }
}

void reportMissingDependencies(
  List<DependencyConfig> deps,
  Iterable<ImportableType> ignoredTypes,
  Iterable<String> ignoredTypesInPackages,
  Uri? targetFile,
  bool throwOnMissingDependencies,
) {
  final messages = [];
  for (final dep in deps) {
    for (var iDep in dep.dependencies.where(
      (d) => !d.isFactoryParam && d.instanceName != kEnvironmentsName,
    )) {
      if ((ignoredTypes.contains(iDep.type) ||
          (iDep.type.import == null ||
              ignoredTypesInPackages.any(
                (type) => iDep.type.import!.startsWith('package:$type'),
              )))) {
        continue;
      }

      final possibleDeps = lookupPossibleDeps(iDep, deps);

      if (possibleDeps.isEmpty) {
        messages.add(
          "[${dep.typeImpl}] depends on unregistered type [${iDep.type}] ${iDep.instanceName == null ? '' : '@Named(${iDep.instanceName})'}, ${iDep.type.import == null ? '' : 'from ${iDep.type.import}'}",
        );
      } else {
        final availableEnvs = possibleDeps
            .map((e) => e.environments)
            .reduce((a, b) => a + b)
            .toSet();
        if (availableEnvs.isNotEmpty) {
          final missingEnvs = dep.environments.toSet().difference(
            availableEnvs,
          );
          if (missingEnvs.isNotEmpty) {
            messages.add(
              '[${dep.typeImpl}] ${dep.environments.toSet()} depends on Type [${iDep.type}]  ${iDep.type.import == null ? '' : 'from ${iDep.type.import}'} \n which is not available under environment keys $missingEnvs',
            );
          }
        }
      }
    }
  }

  if (messages.isNotEmpty) {
    messages.add(
      '\nDid you forget to annotate the above class(s) or their implementation with @injectable? \nor add the right environment keys?',
    );
    if (throwOnMissingDependencies) {
      throw messages.join('\n');
    }
    printBoxed(
      messages.join('\n'),
      header: "Missing dependencies in ${targetFile?.path}\n",
    );
  }
}
