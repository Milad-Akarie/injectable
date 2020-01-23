import 'package:analyzer/dart/element/element.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

class DependencyHolder {
  String className;
  List<String> imports = [];
  List<String> dependencies = [];
  int type;
  String instanceName;
  bool signalsReady;
  String abstractClassName;

  DependencyHolder.fromJson(Map<String, dynamic> json) {
    className = json['className'];
    abstractClassName = json['abstractClassName'];
    instanceName = json['instanceName'];
    signalsReady = json['signalsReady'];
    imports = json['imports'].cast<String>();
    dependencies = json['dependencies'].cast<String>();
    type = json['type'];
  }

  DependencyHolder.fromElement(
      ClassElement element, ConstantReader annotation) {
    // extract data from annotation
    type = annotation.read('_injectableType').intValue;
    instanceName = annotation.peek('_instanceName')?.stringValue;
    signalsReady = annotation.peek('signalsReady')?.boolValue;

    final concreteType = annotation.peek('bindTo')?.typeValue;
    if (concreteType != null) {
      abstractClassName = element.name;
    }
    final ClassElement concreteElement = concreteType?.element ?? element;

    className = concreteElement.name;
    imports = [getImport(element)];
    final constructor = concreteElement.unnamedConstructor;
    if (constructor != null) {
      constructor.parameters.forEach((param) {
        dependencies.add(param.type.element.name);
        imports.add(getImport(param.type.element));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        "className": className,
        "abstractClassName": abstractClassName,
        "type": type,
        "imports": imports.toSet().toList(),
        "dependencies": dependencies.toList(),
        "instanceName": instanceName,
        "signalsReady": signalsReady,
      };
}
