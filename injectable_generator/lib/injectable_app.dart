import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:injectable/injectable_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'injectable_generator.dart';

class InjectableAppGenerator extends GeneratorForAnnotation<Injecater> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    print('Generating');
    final injectorFiles = Glob("**.injecatble.json");
    final List<DependencyHolder> classes = List();
    injectorFiles.listSync().forEach((f) {
      final json = jsonDecode(File(f.path).readAsStringSync());

      classes.add(DependencyHolder.fromJson(json));
    });

    return generateClass(classes, element.name.replaceFirst("\$", ""));
  }

  FutureOr<String> generateClass(List<DependencyHolder> classes, String injectorName) async {
    final buffer = StringBuffer();

    final imports = classes.fold<Set<String>>({}, (a, b) => a..addAll(b.imports));
    imports.forEach((import) {
      buffer.writeln("import $import;");
    });

    buffer.writeln("import 'package:get_it/get_it.dart';");
    buffer.writeln("final GetIt getIt = GetIt.instance;");

    buffer.writeln("class $injectorName {");
    buffer.writeln("static void initialize(){");

    classes.forEach((dep) {
      final constBuffer = StringBuffer();
      dep.dependencies.forEach((claName) {
        constBuffer.write("getIt<$claName>(),");
      });

      buffer.writeln("getIt.registerFactory(() => ${dep.className}(${constBuffer.toString()}));");
    });

    buffer.writeln("}");
    buffer.writeln("}");
    return buffer.toString();
  }
}
