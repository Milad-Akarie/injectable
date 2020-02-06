import 'package:analyzer/dart/element/element.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

const TypeChecker instanceNameChecker = const TypeChecker.fromRuntime(Named);
const TypeChecker singletonChecker = const TypeChecker.fromRuntime(Singleton);
const TypeChecker envrimentChecker = const TypeChecker.fromRuntime(Env);
const TypeChecker bindChecker = const TypeChecker.fromRuntime(Bind);

const TypeChecker constructorChecker = const TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  final ClassElement clazz;
  final ConstantReader _bindReader;

  DependencyResolver(this.clazz, [this._bindReader]);

  DependencyConfig resolve() {
    final dep = DependencyConfig();
    var inlineEnv;
    dep.type = clazz.name;
    dep.bindTo = clazz.name;

    ExecutableElement constructor;
    if (clazz.isAbstract) {
      constructor = clazz.methods.firstWhere((m) => constructorChecker.firstAnnotationOf(m) != null, orElse: () {
        throwBoxed('''[${clazz.name}] is abstract and can not be registered directly!
          \nTry binding it to an Implementation using @Bind.toType()\nor annotating a create method with @factoryMethod''');
        return null;
      });
    } else {
      constructor = clazz.constructors
          .firstWhere((c) => constructorChecker.firstAnnotationOf(c) != null, orElse: () => clazz.unnamedConstructor);
    }
    dep.constructorName = constructor.name;

    ConstantReader bindReader = _bindReader;
    if (bindReader == null) {
      final bindAnnotation = bindChecker.firstAnnotationOf(clazz);
      if (bindAnnotation != null) {
        bindReader = ConstantReader(bindAnnotation);
      }
    }

    if (bindReader != null) {
      if (bindReader.read('_standAlone').boolValue) {
      } else {
        final abstractType = bindReader.peek('to')?.typeValue;
        inlineEnv = bindReader.peek('env')?.stringValue;
        dep.type = abstractType.name;
        dep.bindTo = clazz.name;
        dep.imports.add(getImport(abstractType.element));
      }
    }

    dep.environment = inlineEnv ??
        envrimentChecker.firstAnnotationOfExact(clazz, throwOnUnresolved: false)?.getField('name')?.toStringValue();

    final singletonAnnotation = singletonChecker.firstAnnotationOf(clazz, throwOnUnresolved: false);
    if (singletonAnnotation != null) {
      if (singletonAnnotation.getField('_lazy').toBoolValue()) {
        dep.injectableType = InjectableType.lazySingleton;
      } else {
        dep.injectableType = InjectableType.singleton;
      }

      dep.signalsReady = singletonAnnotation.getField('signalsReady')?.toBoolValue();
    } else {
      dep.injectableType = InjectableType.factory;
    }

    dep.imports.add(getImport(clazz));

    if (constructor != null) {
      constructor.parameters.forEach((param) {
        final namedAnnotation = instanceNameChecker.firstAnnotationOf(param, throwOnUnresolved: false);

        final instanceName = namedAnnotation?.getField('type')?.toTypeValue()?.name ??
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
