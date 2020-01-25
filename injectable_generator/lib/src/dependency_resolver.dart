import 'package:analyzer/dart/element/element.dart';
import 'package:injectable/injectable_annotations.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import '../injectable_types.dart';
import 'dependency_config.dart';

const TypeChecker instanceNameChecker = TypeChecker.fromRuntime(InstanceName);
const TypeChecker singletonChecker = TypeChecker.fromRuntime(Singleton);
const TypeChecker envrimentChcker = TypeChecker.fromRuntime(Environment);

// extracts route configs from class fields
class DependencyResolver {
  final ConstantReader annotation;
  final ClassElement element;

  DependencyResolver(this.element, this.annotation);

  DependencyConfig resolve() {
    final dep = DependencyConfig();
    dep.instanceName = annotation.peek('instanceName')?.stringValue;

    final abstractType = annotation.peek('bindTo')?.typeValue;
    dep.environment = envrimentChcker
        .firstAnnotationOfExact(element, throwOnUnresolved: false)
        ?.getField('name')
        ?.toStringValue();

    final singletonAnnotation =
        singletonChecker.firstAnnotationOf(element, throwOnUnresolved: false);
    if (singletonAnnotation != null) {
      if (singletonAnnotation.getField('_lazy').toBoolValue()) {
        dep.injectableType = InjectableType.lazySingleton;
      } else {
        dep.injectableType = InjectableType.singleton;
      }

      dep.signalsReady =
          singletonAnnotation.getField('signalsReady')?.toBoolValue();
    } else {
      dep.injectableType = InjectableType.factory;
    }

    if (abstractType != null) {
      dep.bindTo = abstractType.name;
      dep.imports.add(getImport(abstractType.element));
    } else {
      dep.bindTo = element.name;
    }

    dep.type = element.name;
    dep.imports.add(getImport(element));
    final constructor = element.unnamedConstructor;
    if (constructor != null) {
      constructor.parameters.forEach((param) {
        final instanceName = instanceNameChecker
            .firstAnnotationOf(param, throwOnUnresolved: false)
            ?.getField('name')
            ?.toStringValue();
        dep.dependencies.add(InjectedDependency(
          type: param.type.element.name,
          name: instanceName,
          import: getImport(param.type.element),
        ));
      });
    }
    return dep;
  }
}
