
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class ExecutableResolver {
  static List<ExecutableElement> getAllExecutables(ClassElement clazz) {
    final Set<String> seenMethods = {};
    final Set<String> seenAccessors = {};

    final List<ExecutableElement> methods = [];
    final List<PropertyAccessorElement> accessors = [];

    InterfaceType? type = clazz.thisType;

    while (type != null) {
      if (type.element.library.isDartCore) {
        break;
      }

      for (final method in type.element.methods) {
        if (!method.isSynthetic && seenMethods.add(method.name)) {
          methods.add(method);
        }
      }

      for (final accessor in type.element.accessors) {
        if (!accessor.isSynthetic && seenAccessors.add(accessor.name)) {
          accessors.add(accessor);
        }
      }

      type = type.superclass;
    }

    for (final mixin in clazz.mixins) {
      for (final method in mixin.element.methods) {
        if (!method.isSynthetic && seenMethods.add(method.name)) {
          methods.add(method);
        }
      }

      for (final accessor in mixin.element.accessors) {
        if (!accessor.isSynthetic && seenAccessors.add(accessor.name)) {
          accessors.add(accessor);
        }
      }
    }

    return [
      ...accessors,
      ...methods,
    ];
  }
}