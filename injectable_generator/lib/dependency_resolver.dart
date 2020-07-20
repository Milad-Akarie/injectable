import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/import_resolver.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

const TypeChecker namedChecker = TypeChecker.fromRuntime(Named);
const TypeChecker singletonChecker = TypeChecker.fromRuntime(Singleton);
const TypeChecker injectableChecker = TypeChecker.fromRuntime(Injectable);

const TypeChecker envChecker = TypeChecker.fromRuntime(Environment);
const TypeChecker preResolveChecker = TypeChecker.fromRuntime(PreResolve);
const TypeChecker factoryParamChecker = TypeChecker.fromRuntime(FactoryParam);
const TypeChecker constructorChecker = TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  Element _annotatedElement;
  final _dep = DependencyConfig();
  final ImportResolver _importResolver;
  final Map<String, String> _typeArgsMap = {};

  DependencyResolver(this._importResolver);

  Future<DependencyConfig> resolve(Element element) {
    _annotatedElement = element;
    _dep.imports.add(_importResolver.resolve(element));
    return _resolveActualType(_annotatedElement);
  }

  Future<DependencyConfig> resolveModuleMember(
    ClassElement moduleClazz,
    ExecutableElement executableElement,
  ) async {
    _annotatedElement = executableElement;
    final returnType = executableElement.returnType;
    String typeName = returnType.getDisplayString();
    if (returnType is ParameterizedType) {
      ClassElement element = returnType.element;
      for (int i = 0; i < element.typeParameters.length; i++) {
        _typeArgsMap[element.typeParameters[i].name] =
            returnType.typeArguments[i].getDisplayString();
      }
    }

    throwIf(
      returnType.element is! ClassElement,
      '${returnType.getDisplayString()} is not a class element',
      element: returnType.element,
    );

    _dep.imports.addAll(_importResolver.resolveAll(returnType));

    _dep.moduleName = moduleClazz.name;
    _dep.initializerName = executableElement.name;
    _dep.imports.add(_importResolver.resolve(moduleClazz));

    ExecutableElement executableModuleMember;
    if (executableElement is MethodElement) {
      _dep.isModuleMethod = true;

      if (!executableElement.isAbstract) {
        executableModuleMember = executableElement;
      } else {
        throwIf(
          executableElement.parameters.isNotEmpty,
          'Abstract methods can not have injectable or factory parameters',
          element: executableElement,
        );
      }
    }

    ClassElement clazz;
    if (executableElement.isAbstract) {
      clazz = returnType.element;
      _dep.isAbstract = true;
    } else {
      if (returnType.isDartAsyncFuture) {
        final typeArg = returnType as ParameterizedType;
        clazz = typeArg.typeArguments.first.element;
        _dep.isAsync = true;
        typeName = typeArg.typeArguments.first.getDisplayString();
      } else {
        clazz = returnType.element;
      }
    }
    _dep.imports.add(_importResolver.resolve(clazz));
    return _resolveActualType(clazz, typeName, executableModuleMember);
  }

  Future<DependencyConfig> _resolveActualType(
    ClassElement clazz, [
    String typeName,
    ExecutableElement excModuleMember,
  ]) async {
    _dep.type = typeName ?? clazz.name;
    _dep.typeImpl = typeName ?? clazz.name;

    final injectableAnnotation = injectableChecker
        .firstAnnotationOf(_annotatedElement, throwOnUnresolved: false);

    var abstractType;
    var inlineEnv;

    // set default injectable type to factory
    _dep.injectableType = InjectableType.factory;

    if (injectableAnnotation != null) {
      final injectable = ConstantReader(injectableAnnotation);
      if (injectable.instanceOf(TypeChecker.fromRuntime(LazySingleton))) {
        _dep.injectableType = InjectableType.lazySingleton;
      } else if (injectable.instanceOf(TypeChecker.fromRuntime(Singleton))) {
        _dep.injectableType = InjectableType.singleton;
        _dep.signalsReady = injectable.peek('signalsReady')?.boolValue;
        _dep.dependsOn = injectable
            .peek('dependsOn')
            ?.listValue
            ?.map<String>((v) => v.toTypeValue().getDisplayString())
            ?.toList();
      }
      abstractType = injectable.peek('as')?.typeValue;
      inlineEnv = injectable
          .peek('env')
          ?.listValue
          ?.map((e) => e.toStringValue())
          ?.toList();
    }

    if (abstractType != null) {
      final abstractChecker = TypeChecker.fromStatic(abstractType);
      final abstractSubtype = clazz.allSupertypes.firstWhere(
          (type) => abstractChecker.isExactly(type.element), orElse: () {
        throwError(
          '[${clazz.name}] is not a subtype of [${abstractType.getDisplayString()}]',
          element: clazz,
        );
        return null;
      });

      _dep.type = abstractSubtype.getDisplayString();

      _dep.typeImpl = clazz.name;
      _dep.imports.addAll(_importResolver.resolveAll(abstractSubtype));
    }

    _dep.environments = inlineEnv ??
        envChecker
            .annotationsOf(_annotatedElement)
            ?.map((e) => e.getField('name')?.toStringValue())
            ?.toList();

    _dep.preResolve = preResolveChecker.hasAnnotationOfExact(_annotatedElement);

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

    ExecutableElement executableInitilizer;

    if (excModuleMember != null) {
      executableInitilizer = excModuleMember;
    } else if (!_dep.isFromModule || _dep.isAbstract) {
      final possibleFactories = <ExecutableElement>[
        ...clazz.methods.where((m) => m.isStatic),
        ...clazz.constructors
      ];

      executableInitilizer = possibleFactories.firstWhere(
          (m) => constructorChecker.hasAnnotationOfExact(m), orElse: () {
        throwIf(
          clazz.isAbstract,
          '''[${clazz.name}] is abstract and can not be registered directly!
           if it has a factory or a create method annotate it with @factoryMethod''',
          element: clazz,
        );
        return clazz.unnamedConstructor;
      });
      _dep.isAsync = executableInitilizer.returnType.isDartAsyncFuture;
    }

    if (executableInitilizer != null) {
      _dep.constructorName = executableInitilizer.name;
      for (ParameterElement param in executableInitilizer.parameters) {
        final namedAnnotation = namedChecker.firstAnnotationOf(param);
        final instanceName = namedAnnotation
                ?.getField('type')
                ?.toTypeValue()
                ?.getDisplayString() ??
            namedAnnotation?.getField('name')?.toStringValue();

        _dep.imports.addAll(_importResolver.resolveAll(param.type));

        var typeName = param.type.getDisplayString();
        if (param.type is TypeParameterType) {
          typeName = _typeArgsMap[param.type.getDisplayString()];
          throwIf(
            typeName == null,
            'Can not resolve dependency of type ${param.type.getDisplayString()}',
            element: param,
          );
        }

        _dep.dependencies.add(InjectedDependency(
          type: typeName,
          name: instanceName,
          isFactoryParam: factoryParamChecker.hasAnnotationOfExact(param),
          paramName: param.name,
          isPositional: param.isPositional,
        ));
      }
      final factoryParamsCount =
          _dep.dependencies.where((d) => d.isFactoryParam).length;

      throwIf(
        _dep.preResolve && factoryParamsCount != 0,
        'Factories with params can not be pre-resolved',
        element: clazz,
      );

      throwIf(
        _dep.isAbstract && factoryParamsCount != 0,
        'Module dependencies with factory params must have custom initializers',
        element: clazz,
      );

      throwIf(
        _dep.injectableType != InjectableType.factory &&
            factoryParamsCount != 0,
        'only factories can have parameters',
        element: clazz,
      );

      throwIf(
        factoryParamsCount > 2,
        'Max number of factory params supported by get_it is 2',
        element: clazz,
      );
    }

    return _dep;
  }
}
