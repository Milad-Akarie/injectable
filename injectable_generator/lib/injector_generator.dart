import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:injectable/injectable_annotations.dart';
import 'package:injectable_generator/injector_config_generator.dart';
import 'package:source_gen/source_gen.dart';

import 'src/dependency_holder.dart';

TypeChecker get injectTypechecker => TypeChecker.fromRuntime(Injectable);

class InjectorGenerator extends GeneratorForAnnotation<InjectorConfig> {
  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    print('\n ------------- Generating injector ----------- \n');

    final injectorFiles = Glob("**.injectable.json");
    final List<DependencyHolder> types = List();

    final FunctionElement methodElement = element;

    injectTypechecker
        .annotationsOfExact(methodElement)
        .where((a) => a.getField('_type') != null)
        .map((a) => AnnotatedElement(
            ConstantReader(a), a.getField('_type').toTypeValue().element))
        .forEach(
      (a) {
        types.add(DependencyHolder.fromElement(a.element, a.annotation));
      },
    );

    List<Map> jsonData = [];
    await for (final id in buildStep.findAssets(injectorFiles)) {
      final json = jsonDecode(await buildStep.readAsString(id));
      jsonData.addAll([...json]);
    }

    jsonData.forEach((json) => types.add(DependencyHolder.fromJson(json)));

    // for (var i = 0; i < 100; i++) {
    //   final content =
    //       "import 'package:injectable/injectable_annotations.dart';@Factory() class Serivce$i {}";
    //   await File('lib/service$i.dart').writeAsString(content);
    // }

    return InjectorConfigGenerator(types, element.name).generate();
  }
}
