import 'package:analyzer/dart/element/element.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

const TypeChecker instanceNameChecker = const TypeChecker.fromRuntime(Named);
const TypeChecker singletonChecker = const TypeChecker.fromRuntime(Singleton);
const TypeChecker envrimentChecker = const TypeChecker.fromRuntime(Environment);
const TypeChecker bindChecker = const TypeChecker.fromRuntime(Bind);

// extracts route configs from class fields
class DependencyResolver {
  final ClassElement element;
  final ConstantReader bindConst;

  DependencyResolver(this.element, [this.bindConst]);

  DependencyConfig resolve() {
    final dep = DependencyConfig();
    var inlineEnv;
    dep.type = element.name;
    dep.bindTo = element.name;
    ConstructorElement constructor = element.unnamedConstructor;

    if (bindConst != null) {
      final concreateType = bindConst.peek('type')?.typeValue;
      final isNamed = bindConst.read('_isNamed').boolValue;
      final name = bindConst.peek('name')?.stringValue;
      inlineEnv = bindConst.peek('env')?.stringValue;

      if (concreateType != null) {
        dep.type = element.name;
        dep.bindTo = concreateType.name;
        constructor =
            (concreateType.element as ClassElement).unnamedConstructor;
        if (isNamed) {
          dep.instanceName = name ?? concreateType.name;
        }
      } else {
        dep.instanceName = name;
      }
    }

    dep.environment = inlineEnv ??
        envrimentChecker
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

    dep.imports.add(getImport(element));

    if (constructor != null) {
      constructor.parameters.forEach((param) {
        final namedAnnotation = instanceNameChecker.firstAnnotationOf(param,
            throwOnUnresolved: false);

        final instanceName =
            namedAnnotation?.getField('type')?.toTypeValue()?.name ??
                namedAnnotation?.getField('name')?.toStringValue();

        dep.dependencies.add(InjectedDependency(
          type: param.type.element.name,
          name: instanceName,
          paramName: param.isPositional ? null : param.name,
          import: getImport(param.type.element),
        ));
      });
    }

    return dep;
  }
}
