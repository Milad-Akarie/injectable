import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'dependency_config.dart';
import 'generator/config_code_generator.dart';
import 'utils.dart';

class InjectableConfigGenerator {
  Future<String> generate(
    Glob assetsGlob,
    BuildStep buildStep,
    Uri targetFile, {
    bool preferRelativeImports = true,
  }) async {
    final jsonData = <Map>[];
    await for (final asset in buildStep.findAssets(assetsGlob)) {
      final json = jsonDecode(await buildStep.readAsString(asset));
      jsonData.addAll([...json]);
    }

    final deps = <DependencyConfig>[];
    jsonData.forEach((json) => deps.add(DependencyConfig.fromJson(json)));

    _reportMissingDependencies(deps, targetFile);
    _validateDuplicateDependencies(deps);
    return ConfigCodeGenerator(deps, targetFile: preferRelativeImports ? targetFile : null).generate();
  }

  void _reportMissingDependencies(List<DependencyConfig> deps, Uri targetFile) {
    final messages = [];
    final registeredDeps = deps.map((dep) => dep.type.identity).toSet();
    deps.forEach((dep) {
      dep.dependencies.where((d) => !d.isFactoryParam).forEach((iDep) {
        final typeIdentity = iDep.type.identity;
        if (!registeredDeps.contains(typeIdentity)) {
          messages.add(
              "[${dep.typeImpl}] depends on unregistered type [${iDep.type.name}] ${iDep.type.import == null ? '' : 'from ${iDep.type.import}'}");
        }
      });
    });

    if (messages.isNotEmpty) {
      messages.add('\nDid you forget to annotate the above classe(s) or their implementation with @injectable?');
      printBoxed(messages.join('\n'), header: "Missing dependencies in ${targetFile.path}\n");
    }
  }

  void _validateDuplicateDependencies(List<DependencyConfig> deps) {
    final validatedDeps = <DependencyConfig>[];
    for (var dep in deps) {
      var registered = validatedDeps.where((elm) => elm.type.identity == dep.type.identity && elm.instanceName == dep.instanceName);
      if (registered.isEmpty) {
        validatedDeps.add(dep);
      } else {
        Set<String> registeredEnvironments = registered.fold(<String>{}, (prev, elm) => prev..addAll(elm.environments));
        if (registeredEnvironments.isEmpty || dep.environments.any((env) => registeredEnvironments.contains(env))) {
          throwBoxed('${dep.typeImpl} [${dep.type}] env: ${dep.environments} \nis registered more than once under the same environment');
        }
      }
    }
  }
}
