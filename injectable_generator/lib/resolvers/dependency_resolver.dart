import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import '../injectable_types.dart';
import 'importable_type_resolver.dart';

const TypeChecker _namedChecker = TypeChecker.fromRuntime(Named);
const TypeChecker _injectableChecker = TypeChecker.fromRuntime(Injectable);

const TypeChecker _envChecker = TypeChecker.fromRuntime(Environment);
const TypeChecker _preResolveChecker = TypeChecker.fromRuntime(PreResolve);
const TypeChecker _factoryParamChecker = TypeChecker.fromRuntime(FactoryParam);
const TypeChecker _factoryMethodChecker =
    TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  final ImportableTypeResolver _typeResolver;

  ImportableType _type;
  ImportableType _typeImpl;
  int _injectableType = InjectableType.factory;
  bool _signalsReady;
  bool _preResolve = false;
  List<ImportableType> _dependsOn;
  List<String> _environments;
  String _instanceName;
  bool _isAsync = false;
  String _constructorName;
  List<InjectedDependency> _dependencies = [];
  ModuleConfig _moduleConfig;

  DependencyResolver(this._typeResolver);

  DependencyConfig resolve(ClassElement element) {
    _type = _typeResolver.resolveType(element.thisType);
    return _resolveActualType(element);
  }

  DependencyConfig resolveModuleMember(
    ClassElement moduleClazz,
    ExecutableElement executableElement,
  ) {
    final moduleType = _typeResolver.resolveType(moduleClazz.thisType);
    final initializerName = executableElement.name;
    final returnType = executableElement.returnType;
    var isAbstract = false;

    throwIf(
      returnType.element is! ClassElement,
      '${returnType.getDisplayString(withNullability: false)} is not a class element',
      element: returnType.element,
    );

    ClassElement clazz;
    var type = returnType;
    if (executableElement.isAbstract) {
      clazz = returnType.element;
      isAbstract = true;
      throwIf(
        executableElement.parameters.isNotEmpty,
        'Abstract methods can not have injectable or factory parameters',
        element: executableElement,
      );
    } else {
      if (returnType.isDartAsyncFuture) {
        final typeArg = returnType as ParameterizedType;
        clazz = typeArg.typeArguments.first.element;
        type = typeArg.typeArguments.first;
      } else {
        clazz = returnType.element;
      }
    }

    this._moduleConfig = ModuleConfig(
      isAbstract: isAbstract,
      isMethod: executableElement is MethodElement,
      type: moduleType,
      initializerName: initializerName,
    );
    this._type = _typeResolver.resolveType(type);
    return _resolveActualType(clazz, executableElement);
  }

  DependencyConfig _resolveActualType(
    ClassElement clazz, [
    ExecutableElement excModuleMember,
  ]) {
    final annotatedElement = excModuleMember ?? clazz;
    _typeImpl = _type;
    final injectableAnnotation = _injectableChecker.firstAnnotationOf(
      annotatedElement,
      throwOnUnresolved: false,
    );

    var asType;
    var inlineEnv;

    if (injectableAnnotation != null) {
      final injectable = ConstantReader(injectableAnnotation);
      if (injectable.instanceOf(TypeChecker.fromRuntime(LazySingleton))) {
        _injectableType = InjectableType.lazySingleton;
      } else if (injectable.instanceOf(TypeChecker.fromRuntime(Singleton))) {
        _injectableType = InjectableType.singleton;
        _signalsReady = injectable.peek('signalsReady')?.boolValue;
        _dependsOn = injectable
            .peek('dependsOn')
            ?.listValue
            ?.map<ImportableType>(
                (type) => _typeResolver.resolveType(type.toTypeValue()))
            ?.toList();
      }
      asType = injectable.peek('as')?.typeValue;
      inlineEnv = injectable
          .peek('env')
          ?.listValue
          ?.map((e) => e.toStringValue())
          ?.toList();
    }

    if (asType != null) {
      final abstractChecker = TypeChecker.fromStatic(asType);
      final abstractSubtype = clazz.allSupertypes.firstWhere(
          (type) => abstractChecker.isExactly(type.element), orElse: () {
        throwError(
          '[${clazz.name}] is not a subtype of [${asType.getDisplayString()}]',
          element: clazz,
        );
        return null;
      });
      _type = _typeResolver.resolveType(abstractSubtype);
    }

    _environments = inlineEnv ??
        _envChecker
            .annotationsOf(annotatedElement)
            ?.map(
              (e) => e.getField('name')?.toStringValue(),
            )
            ?.toList();

    _preResolve = _preResolveChecker.hasAnnotationOfExact(annotatedElement);

    final name = _namedChecker
        .firstAnnotationOfExact(annotatedElement)
        ?.getField('name')
        ?.toStringValue();
    if (name != null) {
      if (name.isNotEmpty) {
        _instanceName = name;
      } else {
        _instanceName = clazz.name;
      }
    }

    ExecutableElement executableInitializer;
    if (excModuleMember != null && !excModuleMember.isAbstract) {
      executableInitializer = excModuleMember;
    } else {
      final possibleFactories = <ExecutableElement>[
        ...clazz.methods.where((m) => m.isStatic),
        ...clazz.constructors,
      ];

      executableInitializer = possibleFactories.firstWhere(
        (m) => _factoryMethodChecker.hasAnnotationOfExact(m),
        orElse: () {
          throwIf(
            clazz.isAbstract,
            '''[${clazz.name}] is abstract and can not be registered directly! \nif it has a factory or a create method annotate it with @factoryMethod''',
            element: clazz,
          );
          return clazz.unnamedConstructor;
        },
      );
    }

    throwIf(
      executableInitializer == null,
      'could not resolve dependency constructor/factory',
    );

    _isAsync = executableInitializer.returnType.isDartAsyncFuture;
    _constructorName = executableInitializer.name;
    for (ParameterElement param in executableInitializer.parameters) {
      final namedAnnotation = _namedChecker.firstAnnotationOf(param);
      final instanceName = namedAnnotation
              ?.getField('type')
              ?.toTypeValue()
              ?.getDisplayString(withNullability: false) ??
          namedAnnotation?.getField('name')?.toStringValue();

      var paramType = param.type;
      _dependencies.add(InjectedDependency(
        type: _typeResolver.resolveType(paramType),
        instanceName: instanceName,
        isFactoryParam: _factoryParamChecker.hasAnnotationOfExact(param),
        paramName: param.name,
        isPositional: param.isPositional,
      ));
    }
    final factoryParamsCount =
        _dependencies.where((d) => d.isFactoryParam).length;

    throwIf(
      _preResolve && factoryParamsCount != 0,
      'Factories with params can not be pre-resolved',
      element: clazz,
    );

    throwIf(
      _moduleConfig?.isAbstract == true && factoryParamsCount != 0,
      'Module dependencies with factory params must have custom initializers',
      element: clazz,
    );

    throwIf(
      _injectableType != InjectableType.factory && factoryParamsCount != 0,
      'only factories can have parameters',
      element: clazz,
    );
    throwIf(
      factoryParamsCount > 2,
      'Max number of factory params supported by get_it is 2',
      element: clazz,
    );

    return DependencyConfig(
      type: _type,
      typeImpl: _typeImpl,
      injectableType: _injectableType,
      dependencies: _dependencies,
      dependsOn: _dependsOn,
      environments: _environments,
      signalsReady: _signalsReady,
      preResolve: _preResolve,
      instanceName: _instanceName,
      moduleConfig: _moduleConfig,
      constructorName: _constructorName,
      isAsync: _isAsync,
    );
  }
}
