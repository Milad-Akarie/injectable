import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/lean_builder/resolvers/lean_importable_type_resolver.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:lean_builder/element.dart';
import 'package:lean_builder/type.dart';

import '../build_utils.dart';

const _injectableChecker = TypeChecker.typeNamed(
  Injectable,
  inPackage: 'injectable',
);
const _lazySingletonChecker = TypeChecker.typeNamed(
  LazySingleton,
  inPackage: 'injectable',
);
const _singletonChecker = TypeChecker.typeNamed(
  Singleton,
  inPackage: 'injectable',
);

const _namedChecker = TypeChecker.typeNamed(Named, inPackage: 'injectable');
const _ignoredChecker = TypeChecker.typeNamed(
  IgnoreParam,
  inPackage: 'injectable',
);
const _envChecker = TypeChecker.typeNamed(Environment, inPackage: 'injectable');
const _preResolveChecker = TypeChecker.typeNamed(
  PreResolve,
  inPackage: 'injectable',
);
const _factoryParamChecker = TypeChecker.typeNamed(
  FactoryParam,
  inPackage: 'injectable',
);
const _scopeChecker = TypeChecker.typeNamed(Scope, inPackage: 'injectable');
const _factoryMethodChecker = TypeChecker.typeNamed(
  FactoryMethod,
  inPackage: 'injectable',
);
const _disposeMethodChecker = TypeChecker.typeNamed(
  DisposeMethod,
  inPackage: 'injectable',
);
const _postConstructChecker = TypeChecker.typeNamed(
  PostConstruct,
  inPackage: 'injectable',
);
const _orderChecker = TypeChecker.typeNamed(Order, inPackage: 'injectable');

class LeanDependencyResolver {
  final LeanTypeResolver _typeResolver;

  late ImportableType _type;
  late ImportableType _typeImpl;
  int _injectableType = InjectableType.factory;
  bool? _signalsReady;
  bool _preResolve = false;
  final List<ImportableType> _dependsOn = [];
  List<String> _environments = [];
  String? _instanceName;
  bool _isAsync = false;
  bool _canBeConst = false;
  String _constructorName = '';
  final List<InjectedDependency> _dependencies = [];
  ModuleConfig? _moduleConfig;
  DisposeFunctionConfig? _disposeFunctionConfig;
  int? _order;
  String? _scope;
  bool _cache = false;

  LeanDependencyResolver(this._typeResolver);

  DependencyConfig resolve(ClassElement element) {
    _type = _typeResolver.resolveType(element.thisType);
    return _resolveActualType(element);
  }

  DependencyConfig resolveModuleMember(
    ClassElement moduleClazz,
    ExecutableElement executableElement,
  ) {
    var moduleType = _typeResolver.resolveType(moduleClazz.thisType);
    var initializerName = executableElement.name;
    var isAbstract = false;

    final returnType = executableElement.returnType;
    throwIf(
      returnType.element is! ClassElement,
      '${returnType.name} is not a class element',
      element: returnType.element,
    );

    Element? clazz;
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
    _moduleConfig = ModuleConfig(
      isAbstract: isAbstract,
      isMethod: executableElement is MethodElement,
      type: moduleType,
      initializerName: initializerName,
    );
    _type = _typeResolver.resolveType(type);
    return _resolveActualType(clazz as ClassElement, executableElement);
  }

  DependencyConfig _resolveActualType(
    ClassElement clazz, [
    ExecutableElement? excModuleMember,
  ]) {
    final annotatedElement = excModuleMember ?? clazz;
    _typeImpl = _type;
    var injectableAnnotation = _injectableChecker.firstAnnotationOf(
      annotatedElement,
    );
    DartType? abstractType;
    ExecutableElement? disposeFuncFromAnnotation;
    List<String>? inlineEnv;
    if (injectableAnnotation != null &&
        injectableAnnotation.constant is ConstObject) {
      final injectable = injectableAnnotation.constant as ConstObject;

      _cache = injectable.getBool('cache')?.value == true;

      if (_lazySingletonChecker.isExactlyType(injectable.type)) {
        _injectableType = InjectableType.lazySingleton;
        disposeFuncFromAnnotation = injectable
            .getFunctionReference('dispose')
            ?.element;
      } else if (_singletonChecker.isExactlyType(injectable.type)) {
        _injectableType = InjectableType.singleton;
        _signalsReady = injectable.getBool('signalsReady')?.value;
        disposeFuncFromAnnotation = injectable
            .getFunctionReference('dispose')
            ?.element;
        var dependsOn = injectable
            .getList('dependsOn')
            ?.value
            .whereType<ConstType>()
            .map<ImportableType>(
              (dartType) => _typeResolver.resolveType(dartType.value),
            )
            .toList();
        if (dependsOn != null) {
          _dependsOn.addAll(dependsOn);
        }
      }
      abstractType = injectable.getTypeRef('as')?.value;
      inlineEnv = injectable
          .getList('env')
          ?.literalValue
          .cast<String>()
          .toList();
      _scope = injectable.getString('scope')?.value;
      _order = injectable.getInt('order')?.value;
    }
    if (abstractType is NamedDartType) {
      final abstractChecker = TypeChecker.fromTypeRef(abstractType);
      var abstractSubtype = clazz.allSupertypes.firstWhereOrNull(
        (type) => abstractChecker.isExactly(type.element),
      );

      throwIf(
        abstractSubtype == null,
        '[${clazz.name}] is not a subtype of [${abstractType.name}]',
        element: clazz,
      );
      _type = _typeResolver.resolveType(abstractSubtype!);
    }

    throwIf(
      _cache == true && _injectableType != InjectableType.factory,
      'Only factory types can be cached',
      element: clazz,
    );

    _environments =
        inlineEnv ??
        _envChecker
            .annotationsOf(annotatedElement)
            .map((e) => e.constant)
            .whereType<ConstObject>()
            .map<String>((e) => e.getString('name')!.value)
            .toList();

    if (_scopeChecker.firstAnnotationOfExact(annotatedElement)
        case var scopeAnnotation?) {
      _scope ??= (scopeAnnotation.constant as ConstObject)
          .getString('name')
          ?.value;
    }

    _preResolve = _preResolveChecker.hasAnnotationOfExact(annotatedElement);
    if (_orderChecker.firstAnnotationOfExact(annotatedElement)
        case var orderAnnotation?) {
      _order = (orderAnnotation.constant as ConstObject)
          .getInt('position')
          ?.value;
    }

    if (_namedChecker.firstAnnotationOfExact(annotatedElement)
        case var nameAnnotation?) {
      final nameValue = (nameAnnotation.constant as ConstObject)
          .getString('name')
          ?.value;
      if (nameValue is String) {
        if (nameValue.isNotEmpty) {
          _instanceName = nameValue;
        } else {
          _instanceName = clazz.name;
        }
      }
    }
    var disposeMethod = clazz.methods.firstWhereOrNull(
      (m) => _disposeMethodChecker.hasAnnotationOfExact(m),
    );
    if (disposeMethod != null) {
      throwIf(
        _injectableType == InjectableType.factory,
        'Factory types can not have a dispose method',
        element: clazz,
      );
      throwIf(
        disposeMethod.parameters.any(
          (p) => p.isRequiredNamed || p.isRequiredPositional || p.isRequired,
        ),
        'Dispose method must not take any required arguments',
        element: disposeMethod,
      );
      _disposeFunctionConfig = DisposeFunctionConfig(
        isInstance: true,
        name: disposeMethod.name,
      );
    } else if (disposeFuncFromAnnotation != null) {
      final params = disposeFuncFromAnnotation.parameters;
      throwIf(
        params.length != 1 ||
            _typeResolver.resolveType(params.first.type) != _type,
        'Dispose function for $_type must have the same signature as FutureOr Function($_type instance)',
        element: disposeFuncFromAnnotation,
      );
      _disposeFunctionConfig = DisposeFunctionConfig(
        name: disposeFuncFromAnnotation.name,
        importableType: _typeResolver.resolveFunctionType(
          disposeFuncFromAnnotation.type,
          disposeFuncFromAnnotation,
        ),
      );
    }

    late ExecutableElement executableInitializer;
    if (excModuleMember != null && !excModuleMember.isAbstract) {
      executableInitializer = excModuleMember;
    } else {
      final possibleFactories = <ExecutableElement>[
        ...clazz.methods.where((m) => m.isStatic),
        ...clazz.constructors,
      ];

      executableInitializer = possibleFactories.firstWhere(
        (m) {
          final annotation = _factoryMethodChecker
              .firstAnnotationOf(m)
              ?.constant;
          if (annotation is ConstObject) {
            _preResolve |= annotation.getBool('preResolve')?.value ?? false;
            return true;
          }
          return false;
        },
        orElse: () {
          final constructor =
              clazz.unnamedConstructor ??
              clazz.constructors.firstWhereOrNull(
                (element) => !element.isPrivate,
              );
          throwIf(
            clazz.hasAbstract || constructor == null,
            '''[${clazz.name}] is abstract and can not be registered directly! \nif it has a factory or a create method annotate it with @factoryMethod''',
            element: clazz,
          );
          if (clazz.unnamedConstructor == null && constructor!.name != 'new') {
            print(
              '''[${clazz.name}] has no constructor annotated with @factoryMethod we wil use the first available constructor [${constructor.name}]''',
            );
          }
          return constructor!;
        },
      );
    }
    _preResolve |= _preResolveChecker.hasAnnotationOf(executableInitializer);

    _isAsync = executableInitializer.returnType.isDartAsyncFuture;

    // named factory or named constructor
    if (executableInitializer.name != "new") {
      _constructorName = executableInitializer.name;
    } else {
      _constructorName = '';
    }
    for (final param in executableInitializer.parameters) {
      final ignoredAnnotation = _ignoredChecker.firstAnnotationOf(param);

      if (ignoredAnnotation != null) {
        throwIf(
          !param.isOptional,
          'Params annotated with @ignoreParam must be optional',
          element: param,
        );
        continue;
      }
      final namedAnnotation =
          _namedChecker.firstAnnotationOf(param)?.constant as ConstObject?;
      final instanceName =
          namedAnnotation?.getTypeRef('type')?.value.name ??
          namedAnnotation?.getString('name')?.value;

      final resolvedType = param.type is FunctionType
          ? _typeResolver.resolveFunctionType(param.type as FunctionType)
          : _typeResolver.resolveType(param.type);
      final isFactoryParam = _factoryParamChecker.hasAnnotationOfExact(param);

      throwIf(
        isFactoryParam && !resolvedType.isNullable && _isAsync,
        'Async factory params must be nullable',
        element: param,
      );

      _dependencies.add(
        InjectedDependency(
          type: resolvedType,
          instanceName: instanceName,
          isFactoryParam: isFactoryParam,
          paramName: param.name,
          isPositional: param.isPositional,
          isRequired: param.isRequired,
        ),
      );
    }

    _canBeConst =
        (executableInitializer is ConstructorElement &&
            executableInitializer.isConst) &&
        _dependencies.isEmpty;
    final factoryParamsCount = _dependencies
        .where((d) => d.isFactoryParam)
        .length;

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

    String? postConstruct;
    bool postConstructReturnsSelf = false;
    for (final method in clazz.methods) {
      final postConstructAnnotation =
          _postConstructChecker
                  .firstAnnotationOf(
                    method,
                  )
                  ?.constant
              as ConstObject?;

      if (postConstructAnnotation != null) {
        throwIf(
          method.isStatic,
          'PostConstruct method can not be static',
          element: method,
        );
        throwIf(
          method.isPrivate,
          'PostConstruct method can not be private',
          element: method,
        );
        throwIf(
          method.parameters.any(
            (e) => e.isRequiredNamed || e.isRequiredPositional,
          ),
          'PostConstruct method can not have required parameters',
          element: method,
        );
        throwIf(
          method.parameters.any(
            (e) => e.isRequiredNamed || e.isRequiredPositional,
          ),
          'PostConstruct method can not have required parameters',
          element: method,
        );
        postConstruct = method.name;
        _isAsync = method.returnType.isDartAsyncFuture;
        _preResolve = postConstructAnnotation.getBool('preResolve')!.value;
        final returnType = _typeResolver.resolveType(
          _isAsync
              ? (method.returnType as ParameterizedType).typeArguments.first
              : method.returnType,
        );

        postConstructReturnsSelf =
            returnType == _type || returnType == _typeImpl;
        break;
      }
    }

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
      disposeFunction: _disposeFunctionConfig,
      orderPosition: _order ?? 0,
      canBeConst: _canBeConst,
      scope: _scope,
      postConstruct: postConstruct,
      postConstructReturnsSelf: postConstructReturnsSelf,
      cache: _cache,
    );
  }
}
