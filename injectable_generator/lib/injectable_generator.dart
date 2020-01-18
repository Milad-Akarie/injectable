import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:injectable/injectable_annotations.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

class InjectableGenerator extends Generator {
  TypeChecker get typeChecker => TypeChecker.fromRuntime(Injectable);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = Set<String>();

    final list = await Glob('**.app.dart').list().toList();
    list.forEach((f) async {
      print('deleting');
      await f.delete();
    });

    print('after deleting');
    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      generateForAnnotatedElement(annotatedElement.element, annotatedElement.annotation, buildStep);
    }
    return values.join('\n\n');
  }

  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    // Glob('**.app.dart').listSync().forEach((f) => f.delete());

    // buildStep.findAssets(Glob('**.app.dart'));

    if (element is! ClassElement) {
      return null;
    }

    final ClassElement classElement = element;

    final inputID = buildStep.inputId.changeExtension(".injecatble.json");

    final imports = [getImport(element)];
    final constructor = classElement.unnamedConstructor;
    final List<String> dependencies = [];
    if (constructor != null) {
      constructor.parameters.forEach((param) {
        dependencies.add(param.type.element.name);
        imports.add(getImport(param.type.element));
      });
    }
    final dep = DependencyHolder(className: classElement.name, imports: imports, dependencies: dependencies);
    return buildStep.writeAsString(inputID, json.encode(dep.toJson()));
  }
}

class DependencyHolder {
  String className;
  List<String> imports = List();
  List<String> dependencies = List();

  DependencyHolder({this.className, this.imports, this.dependencies});

  DependencyHolder.fromJson(Map<String, dynamic> json) {
    className = json['className'];
    imports = json['import'].cast<String>();
    dependencies = json['dependencies'].cast<String>();
  }

  Map<String, dynamic> toJson() => {"className": className, "import": imports.toList(), "dependencies": dependencies.toList()};
}
