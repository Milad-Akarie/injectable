import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:injectable_generator_micropackages/model/micro_package_model.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';
import 'package:source_gen/source_gen.dart';

/// Runs for classes with @MicroPackage annotation
/// generates a <moduleName>.micropackage.json file for each
/// This Generator runs inside each micropackage module
class InjectableMicroPackagesModuleScout extends GeneratorForAnnotation<MicroPackage>{
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    var visitor = ModelClassVisitor();
    // register visitor
    element.visitChildren(visitor);
    String name = annotation.read('moduleName').stringValue;

    /* old and deprecated, since it's not using visitor

    String location = element.location.components.first;
    String moduleClassName = LibraryReader(element.library).classes.first.name;
    String methodName = LibraryReader(element.library).classes.first.methods.first.name;
    */
    String moduleClassName = visitor.className!.getDisplayString(withNullability: false);
    String? location = visitor.location;
    String methodName = visitor.methodNames.first;


    log.fine("element.name ${name}");
    log.fine("element.location ${location}");
    log.fine(" LibraryReader(element).classes.first.name ${ moduleClassName}");
    log.fine(" methodName ${ methodName}");
    return jsonEncode(MicroPackageModuleModel(location,name, moduleClassName, methodName: methodName));
  }

}

/// Implementation of visitor pattern to get all the existent classes
/// and register ModelClassMethodsVisitor to each of them
class ModelClassVisitor extends SimpleElementVisitor<ClassElement>{

  DartType? className;
  var methodNames = <String>[];
  String? location;

  /// For each method inside class element, the visitor will be called
  /// It will store the method name
  @override
  visitMethodElement(MethodElement element) {
    methodNames.add(element.name);
  }


  @override
  ClassElement? visitCompilationUnitElement(CompilationUnitElement element) {
    location = element.location!.components.first;
    return null;
  }

  @override
  visitLibraryElement(LibraryElement element) {
    //not working
    assert(location== null);
    location = element.location!.components.first;
  }

  @override
  ClassElement? visitConstructorElement(ConstructorElement element) {
    assert(className == null);
    location = element.location!.components.first;
    className = element.type.returnType;
    return null;
  }
}
/// Implementation of visitor pattern to get all the methods that exist
/// in one class. Values are stored in methodNames array
class ModelClassMethodsVisitor extends SimpleElementVisitor{

}