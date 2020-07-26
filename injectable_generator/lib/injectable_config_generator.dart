import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:injectable/injectable.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'generator/config_code_generator.dart';
import 'utils.dart';

class InjectableConfigGenerator extends GeneratorForAnnotation<InjectableInit> {
  @override
  dynamic generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    final generateForDir = annotation.read('generateForDir').listValue.map((e) => e.toStringValue());

    var targetFile;
    if (annotation.peek("preferRelativeImports")?.boolValue ?? true == true) {
      targetFile = element.source.uri;
    }

    final dirPattern = generateForDir.length > 1 ? '{${generateForDir.join(',')}}' : '${generateForDir.first}';
    final injectableConfigFiles = Glob("$dirPattern/**.injectable.json");

    final jsonData = <Map>[];
    await for (final id in buildStep.findAssets(injectableConfigFiles)) {
      final json = jsonDecode(await buildStep.readAsString(id));
      jsonData.addAll([...json]);
    }

    final deps = <DependencyConfig>[];
    jsonData.forEach((json) => deps.add(DependencyConfig.fromJson(json)));

    _reportMissingDependencies(deps);
    _validateDuplicateDependencies(deps);
    return ConfigCodeGenerator(deps, targetFile: targetFile).generate();
  }

  void _reportMissingDependencies(List<DependencyConfig> deps) {
    final messages = [];
    final registeredDeps = deps.map((dep) => stripGenericTypes(dep.type.name)).toSet();
    deps.forEach((dep) {
      dep.dependencies.where((d) => !d.isFactoryParam).forEach((iDep) {
        final typeName = iDep.type.name;
        if (!registeredDeps.contains(typeName)) {
          messages.add("[${dep.typeImpl}] depends on [$typeName] which is not injectable!");
        }
      });
    });

    if (messages.isNotEmpty) {
      messages.add('\nDid you forget to annotate the above classe(s) or their implementation with @injectable?');
      printBoxed(messages.join('\n'));
    }
  }

  void _validateDuplicateDependencies(List<DependencyConfig> deps) {
    final registeredDeps = <DependencyConfig>[];
    for (var dep in deps) {
      var registered = registeredDeps.where((elm) => elm.type.name == dep.type.name && elm.instanceName == dep.instanceName);
      if (registered.isEmpty) {
        registeredDeps.add(dep);
      } else {
        Set<String> registeredEnvironments = registered.fold(<String>{}, (prev, elm) => prev..addAll(elm.environments));
        if (registeredEnvironments.isEmpty || dep.environments.any((env) => registeredEnvironments.contains(env))) {
          throwBoxed('${dep.typeImpl} [${dep.type}] env: ${dep.environments} \nis registered more than once under the same environment');
        }
      }
    }
  }
}
