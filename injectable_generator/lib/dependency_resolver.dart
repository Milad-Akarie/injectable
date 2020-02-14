import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

const TypeChecker namedChecker = const TypeChecker.fromRuntime(Named);
const TypeChecker singletonChecker = const TypeChecker.fromRuntime(Singleton);
const TypeChecker envChecker = const TypeChecker.fromRuntime(Environment);
const TypeChecker bindChecker = const TypeChecker.fromRuntime(RegisterAs);

const TypeChecker constructorChecker =
    const TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  final Element _annotatedElement;
  final _dep = DependencyConfig();

  DependencyResolver(this._annotatedElement) {
    _dep.imports.add(getImport(_annotatedElement));
    _resolve(_annotatedElement);
  }

  DependencyResolver.fromAccessor(this._annotatedElement, String registerModuleCode, LibraryElement lib) {
    final PropertyAccessorElement accessorElement = _annotatedElement;
    final returnType = accessorElement.returnType;

    if (returnType.element is! ClassElement) {
      throwBoxed('${returnType.name} is not a class element');
    } else {
      ClassElement clazz;
      if (accessorElement.isAbstract) {
        clazz = returnType.element;
      } else {
        final initializer = Initializer();
        final arrowReg = RegExp('${accessorElement.declaration}\\s+=>([^;]*)');
        if (arrowReg.hasMatch(registerModuleCode)) {
          initializer.code =
              arrowReg.firstMatch(registerModuleCode).group(1).trim();
          initializer.isClosure = true;
        } else {
          throwBoxed(
              'Error parsing ${accessorElement.name} getter body! \nonly expressions [=>] are supported');
        }

        if (returnType.isDartAsyncFuture) {
          final typeArg = returnType as ParameterizedType;
          clazz = typeArg.typeArguments.first.element;
          initializer.isAsync = true;
        } else {
          clazz = returnType.element;
        }
        _dep.initializer = initializer;
      }

      _resolve(clazz);

      if (lib != null) {
        _dep.imports.add(getImport(lib));
      } else {
        _dep.imports.add(getImport(clazz));
      }
    }
  }

  DependencyConfig _resolve(ClassElement clazz) {
    _dep.type = clazz.name;
    _dep.bindTo = clazz.name;

    var inlineEnv;
    final bindAnnotation = bindChecker.firstAnnotationOf(_annotatedElement);
    if (bindAnnotation != null) {
      ConstantReader bindReader = ConstantReader(bindAnnotation);
      final abstractType = bindReader.peek('abstractType')?.typeValue;
      inlineEnv = bindReader.peek('env')?.stringValue;
      _dep.type = abstractType.name;
      _dep.bindTo = clazz.name;
      _dep.imports.add(getImport(abstractType.element));
    }

    _dep.environment = inlineEnv ??
        envChecker
            .firstAnnotationOfExact(_annotatedElement, throwOnUnresolved: false)
            ?.getField('name')
            ?.toStringValue();

    final name = namedChecker
        .firstAnnotationOfExact(_annotatedElement)
        ?.getField('name')
        ?.toStringValue();
    if (name != null) {
      if (name.isNotEmpty) {
        _dep.instanceName = name;
      } else {
        _dep.instanceName = clazz.name;
      }
    }

    final singletonAnnotation = singletonChecker
        .firstAnnotationOf(_annotatedElement, throwOnUnresolved: false);
    if (singletonAnnotation != null) {
      if (singletonAnnotation.getField('_lazy').toBoolValue()) {
        _dep.injectableType = InjectableType.lazySingleton;
      } else {
        _dep.injectableType = InjectableType.singleton;
      }

      _dep.signalsReady =
          singletonAnnotation.getField('signalsReady')?.toBoolValue();
    } else {
      _dep.injectableType = InjectableType.factory;
    }

    ExecutableElement constructor;
    if (_dep.initializer == null) {
      final possibleFactories = <ExecutableElement>[
        ...clazz.methods.where((m) => m.isStatic),
        ...clazz.constructors
      ];

      constructor = possibleFactories
          .firstWhere((m) => constructorChecker.hasAnnotationOf(m), orElse: () {
        if (clazz.isAbstract) {
          throwBoxed(
              '''[${_annotatedElement.name}] is abstract and can not be registered directly!
          \n if it has a factory or a create method annotate it with @factoryMethod''');
        }
        return clazz.unnamedConstructor;
      });
    }
    if (constructor != null) {
      _dep.constructorName = constructor.name;

      constructor.parameters.forEach((param) {
        final namedAnnotation = namedChecker.firstAnnotationOf(param);

        final instanceName =
            namedAnnotation?.getField('type')?.toTypeValue()?.name ??
                namedAnnotation?.getField('name')?.toStringValue();

        _dep.dependencies.add(InjectedDependency(
          type: param.type.element.name,
          name: instanceName,
          paramName: param.isPositional ? null : param.name,
          import: getImport(param.type.element),
        ));
      });
    }

    return _dep;
  }

  DependencyConfig get resolvedDependency => _dep;
}
