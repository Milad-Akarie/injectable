import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';
import 'package:injectable_generator_micropackages/importable_type_resolver.dart';
import 'package:injectable_generator_micropackages/utils.dart';
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
  final ImportableTypeResolver _importResolver;
  final Map<String, DartType> _typeArgsMap = {};

  DependencyResolver(this._importResolver);

  Future<DependencyConfig> resolve(Element element) {
    _annotatedElement = element;
    return _resolveActualType(_annotatedElement);
  }

  Future<DependencyConfig> resolveModuleMember(
    ClassElement moduleClazz,
    ExecutableElement executableElement,
  ) async {
    _annotatedElement = executableElement;
    final returnType = executableElement.returnType;

    if (returnType is ParameterizedType) {
      ClassElement element = returnType.element;
      for (int i = 0; i < element.typeParameters.length; i++) {
        _typeArgsMap[element.typeParameters[i].name] = returnType.typeArguments[i];
      }
    }

    throwIf(
      returnType.element is! ClassElement,
      '${returnType.getDisplayString(withNullability: false)} is not a class element',
      element: returnType.element,
    );

    _dep.module = _importResolver.resolveType(moduleClazz.thisType);
    _dep.initializerName = executableElement.name;

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
    var type = returnType;
    if (executableElement.isAbstract) {
      clazz = returnType.element;
      _dep.isAbstract = true;
    } else {
      if (returnType.isDartAsyncFuture) {
        final typeArg = returnType as ParameterizedType;
        clazz = typeArg.typeArguments.first.element;
        _dep.isAsync = true;
        type = typeArg.typeArguments.first;
      } else {
        clazz = returnType.element;
      }
    }

    return _resolveActualType(clazz, type, executableModuleMember);
  }

  Future<DependencyConfig> _resolveActualType(
    ClassElement clazz, [
    DartType type,
    ExecutableElement excModuleMember,
  ]) async {
    _dep.type = _importResolver.resolveType(type ?? clazz.thisType);
    _dep.typeImpl = _dep.type;

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
        _dep.signalsReady = injectable
            .peek('signalsReady')
            ?.boolValue;
        _dep.dependsOn = injectable
            .peek('dependsOn')
            ?.listValue
            ?.map<String>(
                (v) => v.toTypeValue().getDisplayString(withNullability: false))
            ?.toList();
      }
      abstractType = injectable
          .peek('as')
          ?.typeValue;
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

      _dep.type = _importResolver.resolveType(abstractSubtype);
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
          '''[${clazz
              .name}] is abstract and can not be registered directly! \nif it has a factory or a create method annotate it with @factoryMethod''',
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
            ?.getDisplayString(withNullability: false) ??
            namedAnnotation?.getField('name')?.toStringValue();

        var paramType = param.type;
        if (paramType is TypeParameterType) {
          paramType =
          _typeArgsMap[paramType.getDisplayString(withNullability: false)];
        }

        ImportableType resolvedType;
        if (paramType != null) {
          resolvedType = _importResolver.resolveType(paramType);
        } else {
          resolvedType = ImportableType(name: 'dynamic');
        }

        _dep.dependencies.add(InjectedDependency(
          type: resolvedType,
          name: instanceName,
          isFactoryParam: factoryParamChecker.hasAnnotationOfExact(param),
          paramName: param.name,
          isPositional: param.isPositional,
        ));
      }
      final factoryParamsCount =
          _dep.dependencies
              .where((d) => d.isFactoryParam)
              .length;

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
