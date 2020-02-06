import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:injectable/injectable.dart';
import 'package:source_gen/source_gen.dart';

import 'config_code_generator.dart';
import 'dependency_config.dart';
import 'utils.dart';

const TypeChecker bindChecker = const TypeChecker.fromRuntime(Bind);

class InjectableConfigGenerator extends GeneratorForAnnotation<InjectableInit> {
  final injectableConfigFiles = Glob("**.injectable.json");

  @override
  dynamic generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    final List<Map> jsonData = [];
    await for (final id in buildStep.findAssets(injectableConfigFiles)) {
      final json = jsonDecode(await buildStep.readAsString(id));
      jsonData.addAll([...json]);
    }

    final deps = <DependencyConfig>[];
    jsonData.forEach((json) => deps.add(DependencyConfig.fromJson(json)));

    bindChecker.annotationsOfExact(element).map((a) => ConstantReader(a)).forEach((bindReader) {
      print(bindReader);
    });

    _reportMissingDependencies(deps);
    return ConfigCodeGenerator(deps).generate();
  }

  void _reportMissingDependencies(List<DependencyConfig> deps) {
    final messages = [];
    final registeredDeps = deps.map((dep) => dep.type).toSet();
    deps.forEach((dep) {
      dep.dependencies.forEach((idep) {
        if (!registeredDeps.contains(idep.type)) {
          messages.add("[${dep.bindTo}] depends on [${idep.type}] which is not injectable!");
        }
      });
    });

    if (messages.isNotEmpty) {
      messages.add('\nDid you forget to annotate the above classe(s) or their implementation with @injectable?');
      printBoxed(messages.join('\n'));
    }
  }
}
