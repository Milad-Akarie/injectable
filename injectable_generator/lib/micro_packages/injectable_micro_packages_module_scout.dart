import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/model/micro_package_model.dart';
import 'package:source_gen/source_gen.dart';

/// Runs for classes with @MicroPackage annotation
/// generates a <moduleName>.micropackage.json file for each
/// This Generator runs inside each micropackage module
class InjectableMicroPackagesModuleScout extends GeneratorForAnnotation<MicroPackage>{
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {

    String name = annotation.read('moduleName').stringValue;
    String location = element.location.components.first;

    String moduleClassName = LibraryReader(element.library).classes.first.name;
    String methodName = LibraryReader(element.library).classes.first.methods.first.name;

    log.fine("element.name ${name}");
    log.fine("element.location ${location}");
    log.fine(" LibraryReader(element).classes.first.name ${ moduleClassName}");
    log.fine(" methodName ${ methodName}");
    return jsonEncode(MicroPackageModuleModel(location,name, moduleClassName, methodName: methodName));
  }

}