import 'package:analyzer/dart/element/element.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

const TypeChecker namedChecker = const TypeChecker.fromRuntime(Named);
const TypeChecker singletonChecker = const TypeChecker.fromRuntime(Singleton);
const TypeChecker envrimentChecker = const TypeChecker.fromRuntime(Envirnoment);
const TypeChecker bindChecker = const TypeChecker.fromRuntime(RegisterAs);

const TypeChecker constructorChecker =
    const TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  final Element element;
  DependencyResolver(this.element);

  Future<DependencyConfig> resolve() async {
    final dep = DependencyConfig();

    ClassElement clazz;
    if (element is ClassElement) {
      clazz = element;
    } else if (element is PropertyAccessorElement) {
      final PropertyAccessorElement accessorElement = element;
      final returnType = accessorElement.returnType;
      if (returnType.element is! ClassElement) {
        throwBoxed('${returnType.name} is not a class element');
      } else {
        clazz = returnType.element;
      }
    }

    dep.imports.add(getImport(clazz));

    dep.type = clazz.name;
    dep.bindTo = clazz.name;

    var inlineEnv;
    final bindAnnotation = bindChecker.firstAnnotationOf(element);
    if (bindAnnotation != null) {
      ConstantReader bindReader = ConstantReader(bindAnnotation);
      final abstractType = bindReader.peek('abstractType')?.typeValue;
      inlineEnv = bindReader.peek('env')?.stringValue;
      dep.type = abstractType.name;
      dep.bindTo = clazz.name;
      dep.imports.add(getImport(abstractType.element));
    }

    dep.environment = inlineEnv ??
        envrimentChecker
            .firstAnnotationOfExact(element, throwOnUnresolved: false)
            ?.getField('name')
            ?.toStringValue();

    final name = namedChecker
        .firstAnnotationOfExact(element)
        ?.getField('name')
        ?.toStringValue();
    if (name != null) {
      if (name.isNotEmpty) {
        dep.instanceName = name;
      } else {
        dep.instanceName = clazz.name;
      }
    }

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

    ExecutableElement constructor;
    if (clazz.isAbstract) {
      constructor = clazz.methods.firstWhere(
          (m) => constructorChecker.firstAnnotationOf(m) != null, orElse: () {
        throwBoxed(
            '''[${element.name}] is abstract and can not be registered directly!
          \n if it ha a create method annotate with @factoryMethod''');
        return null;
      });
    } else {
      constructor = clazz.constructors.firstWhere(
          (c) => constructorChecker.firstAnnotationOf(c) != null,
          orElse: () => clazz.unnamedConstructor);
    }
    dep.constructorName = constructor.name;

    if (constructor != null) {
      constructor.parameters.forEach((param) {
        final namedAnnotation = namedChecker.firstAnnotationOf(param);

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
