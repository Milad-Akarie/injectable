import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
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
    var visitor = ModelClassVisitor();
    element.visitChildren(visitor);

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

/// Implementation of visitor pattern to get all the existent classes
/// and register ModelClassMethodsVisitor to each of them
class ModelClassVisitor<Element> extends SimpleElementVisitor{

  /// Maps class names to a visitor
  var classVisitorMap = Map<String,ElementVisitor<ClassElement>>();

  ///For each class inside element, this visitor will be called
  ///It stores the class name and the assigned methods listener so we can
  ///get all the methods the class has
  @override
  visitClassElement(ClassElement element) {
    ElementVisitor visitor = ModelClassMethodsVisitor();
    classVisitorMap[element.name]=  visitor;
    return element;
  }
}
/// Implementation of visitor pattern to get all the methods that exist
/// in one class. Values are stored in methodNames array
class ModelClassMethodsVisitor extends SimpleElementVisitor{
  var methodNames = <String>[];

  /// For each method inside class element, the visitor will be called
  /// It will store the method name
  @override
  visitMethodElement(MethodElement element) {
    methodNames.add(element.name);
    return element;
  }
}