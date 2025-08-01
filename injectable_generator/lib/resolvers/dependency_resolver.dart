import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import '../injectable_types.dart';
import 'importable_type_resolver.dart';

const TypeChecker _namedChecker = TypeChecker.fromRuntime(Named);
const TypeChecker _ignoredChecker = TypeChecker.fromRuntime(IgnoreParam);
const TypeChecker _injectableChecker = TypeChecker.fromRuntime(Injectable);
const TypeChecker _envChecker = TypeChecker.fromRuntime(Environment);
const TypeChecker _preResolveChecker = TypeChecker.fromRuntime(PreResolve);
const TypeChecker _factoryParamChecker = TypeChecker.fromRuntime(FactoryParam);
const TypeChecker _scopeChecker = TypeChecker.fromRuntime(Scope);
const TypeChecker _factoryMethodChecker =
    TypeChecker.fromRuntime(FactoryMethod);
const TypeChecker _disposeMethodChecker =
    TypeChecker.fromRuntime(DisposeMethod);
const TypeChecker _postConstructChecker =
    TypeChecker.fromRuntime(PostConstruct);

const TypeChecker _orderChecker = TypeChecker.fromRuntime(Order);

class DependencyResolver {
  final ImportableTypeResolver _typeResolver;

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
  String? _constructorName;
  final List<InjectedDependency> _dependencies = [];
  ModuleConfig? _moduleConfig;
  DisposeFunctionConfig? _disposeFunctionConfig;
  int? _order;
  String? _scope;

  DependencyResolver(this._typeResolver);

  DependencyConfig resolve(ClassElement2 element) {
    _type = _typeResolver.resolveType(element.thisType);
    return _resolveActualType(element);
  }

  DependencyConfig resolveModuleMember(
    ClassElement2 moduleClazz,
    ExecutableElement2 executableElement,
  ) {
    var moduleType = _typeResolver.resolveType(moduleClazz.thisType);
    var initializerName = executableElement.displayName;
    var isAbstract = false;

    final returnType = executableElement.returnType;
    throwIf(
      returnType.element3 is! ClassElement2,
      '${returnType.nameWithoutSuffix} is not a class element',
      element: returnType.element3,
    );

    Element2? clazz;
    var type = returnType;
    if (executableElement.isAbstract) {
      clazz = returnType.element3;
      isAbstract = true;
      throwIf(
        executableElement.formalParameters.isNotEmpty,
        'Abstract methods can not have injectable or factory parameters',
        element: executableElement,
      );
    } else {
      if (returnType.isDartAsyncFuture) {
        final typeArg = returnType as ParameterizedType;
        clazz = typeArg.typeArguments.first.element3;
        type = typeArg.typeArguments.first;
      } else {
        clazz = returnType.element3;
      }
    }
    _moduleConfig = ModuleConfig(
      isAbstract: isAbstract,
      isMethod: executableElement is MethodElement2,
      type: moduleType,
      initializerName: initializerName,
    );
    _type = _typeResolver.resolveType(type);
    return _resolveActualType(clazz as ClassElement2, executableElement);
  }

  DependencyConfig _resolveActualType(
    ClassElement2 clazz, [
    ExecutableElement2? excModuleMember,
  ]) {
    final annotatedElement = excModuleMember ?? clazz;
    _typeImpl = _type;
    var injectableAnnotation = _injectableChecker.firstAnnotationOf(
      annotatedElement,
      throwOnUnresolved: false,
    );

    DartType? abstractType;
    ExecutableElement2? disposeFuncFromAnnotation;
    List<String>? inlineEnv;
    if (injectableAnnotation != null) {
      final injectable = ConstantReader(injectableAnnotation);
      if (injectable.instanceOf(TypeChecker.fromRuntime(LazySingleton))) {
        _injectableType = InjectableType.lazySingleton;
        disposeFuncFromAnnotation =
            injectable.peek('dispose')?.objectValue.toFunctionValue2();
      } else if (injectable.instanceOf(TypeChecker.fromRuntime(Singleton))) {
        _injectableType = InjectableType.singleton;
        _signalsReady = injectable.peek('signalsReady')?.boolValue;
        disposeFuncFromAnnotation =
            injectable.peek('dispose')?.objectValue.toFunctionValue2();
        var dependsOn = injectable
            .peek('dependsOn')
            ?.listValue
            .map((type) => type.toTypeValue())
            .where((v) => v != null)
            .map<ImportableType>(
                (dartType) => _typeResolver.resolveType(dartType!))
            .toList();
        if (dependsOn != null) {
          _dependsOn.addAll(dependsOn);
        }
      }
      abstractType = injectable.peek('as')?.typeValue;
      inlineEnv = injectable
          .peek('env')
          ?.listValue
          .map((e) => e.toStringValue()!)
          .toList();
      _scope = injectable.peek('scope')?.stringValue;
      _order = injectable.peek('order')?.intValue;
    }
    if (abstractType != null) {
      final abstractChecker = TypeChecker.fromStatic(abstractType);
      var abstractSubtype = clazz.allSupertypes
          .firstWhereOrNull((type) => abstractChecker.isExactly(type.element3));

      throwIf(
        abstractSubtype == null,
        '[${clazz.displayName}] is not a subtype of [${abstractType.nameWithoutSuffix}]',
        element: clazz,
      );

      _type = _typeResolver.resolveType(abstractSubtype!);
    }

    _environments = inlineEnv ??
        _envChecker
            .annotationsOf(annotatedElement, throwOnUnresolved: false)
            .map<String>(
              (e) => e.getField('name')!.toStringValue()!,
            )
            .toList();
    _scope ??= _scopeChecker
        .firstAnnotationOfExact(annotatedElement, throwOnUnresolved: false)
        ?.getField('name')
        ?.toStringValue();
    _preResolve = _preResolveChecker.hasAnnotationOfExact(annotatedElement,
        throwOnUnresolved: false);
    _order ??= _orderChecker
            .firstAnnotationOfExact(annotatedElement, throwOnUnresolved: false)
            ?.getField('position')
            ?.toIntValue() ??
        0;

    final name = _namedChecker
        .firstAnnotationOfExact(annotatedElement, throwOnUnresolved: false)
        ?.getField('name')
        ?.toStringValue();
    if (name != null) {
      if (name.isNotEmpty) {
        _instanceName = name;
      } else {
        _instanceName = clazz.displayName;
      }
    }

    var disposeMethod = clazz.methods2
        .firstWhereOrNull((m) => _disposeMethodChecker.hasAnnotationOfExact(m));
    if (disposeMethod != null) {
      throwIf(
        _injectableType == InjectableType.factory,
        'Factory types can not have a dispose method',
        element: clazz,
      );
      throwIf(
        disposeMethod.formalParameters.any(
            (p) => p.isRequiredNamed || p.isRequiredPositional || p.isRequired),
        'Dispose method must not take any required arguments',
        element: disposeMethod,
      );
      _disposeFunctionConfig = DisposeFunctionConfig(
        isInstance: true,
        name: disposeMethod.displayName,
      );
    } else if (disposeFuncFromAnnotation != null) {
      final params = disposeFuncFromAnnotation.formalParameters;
      throwIf(
          params.length != 1 ||
              _typeResolver.resolveType(params.first.type) != _type,
          'Dispose function for $_type must have the same signature as FutureOr Function($_type instance)',
          element: disposeFuncFromAnnotation);
      _disposeFunctionConfig = DisposeFunctionConfig(
        name: disposeFuncFromAnnotation.displayName,
        importableType: _typeResolver.resolveFunctionType(
            disposeFuncFromAnnotation.type, disposeFuncFromAnnotation),
      );
    }

    late ExecutableElement2 executableInitializer;
    if (excModuleMember != null && !excModuleMember.isAbstract) {
      executableInitializer = excModuleMember;
    } else {
      final possibleFactories = <ExecutableElement2>[
        ...clazz.methods2.where((m) => m.isStatic),
        ...clazz.constructors2,
      ];

      executableInitializer = possibleFactories.firstWhere(
        (m) {
          final annotation = _factoryMethodChecker.firstAnnotationOf(m);
          if (annotation != null) {
            _preResolve |=
                annotation.getField('preResolve')!.toBoolValue() ?? false;
            return true;
          }
          return false;
        },
        orElse: () {
          throwIf(
            clazz.isAbstract,
            '''[${clazz.displayName}] is abstract and can not be registered directly! \nif it has a factory or a create method annotate it with @factoryMethod''',
            element: clazz,
          );
          return clazz.unnamedConstructor2 as ExecutableElement2;
        },
      );
    }
    _preResolve |= _preResolveChecker.hasAnnotationOf(executableInitializer);

    _isAsync = executableInitializer.returnType.isDartAsyncFuture;
    _constructorName = executableInitializer.displayName;
    for (FormalParameterElement param
        in executableInitializer.formalParameters) {
      final ignoredAnnotation =
          _ignoredChecker.firstAnnotationOf(param, throwOnUnresolved: false);

      if (ignoredAnnotation != null) {
        throwIf(
          !param.isOptional,
          'Params annotated with @ignoreParam must be optional',
          element: param,
        );
        continue;
      }
      final namedAnnotation =
          _namedChecker.firstAnnotationOf(param, throwOnUnresolved: false);
      final instanceName =
          namedAnnotation?.getField('type')?.toTypeValue()?.nameWithoutSuffix ??
              namedAnnotation?.getField('name')?.toStringValue();

      final resolvedType = param.type is FunctionType
          ? _typeResolver.resolveFunctionType(param.type as FunctionType)
          : _typeResolver.resolveType(param.type);
      final isFactoryParam = _factoryParamChecker.hasAnnotationOfExact(param,
          throwOnUnresolved: false);

      throwIf(
        isFactoryParam && !resolvedType.isNullable && _isAsync,
        'Async factory params must be nullable',
        element: param,
      );

      _dependencies.add(InjectedDependency(
        type: resolvedType,
        instanceName: instanceName,
        isFactoryParam: isFactoryParam,
        paramName: param.displayName,
        isPositional: param.isPositional,
      ));
    }

    _canBeConst = (executableInitializer is ConstructorElement2 &&
            executableInitializer.isConst) &&
        _dependencies.isEmpty;
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

    String? postConstruct;
    bool postConstructReturnsSelf = false;
    for (final method in clazz.methods2) {
      final postConstructAnnotation =
          _postConstructChecker.firstAnnotationOf(method);
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
          method.formalParameters
              .any((e) => e.isRequiredNamed || e.isRequiredPositional),
          'PostConstruct method can not have required parameters',
          element: method,
        );
        throwIf(
          method.formalParameters
              .any((e) => e.isRequiredNamed || e.isRequiredPositional),
          'PostConstruct method can not have required parameters',
          element: method,
        );
        postConstruct = method.displayName;
        _isAsync = method.returnType.isDartAsyncFuture;
        _preResolve = ConstantReader(postConstructAnnotation)
            .read('preResolve')
            .boolValue;
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
    if (_constructorName == _typeImpl.name) {
      _constructorName = '';
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
      orderPosition: _order!,
      canBeConst: _canBeConst,
      scope: _scope,
      postConstruct: postConstruct,
      postConstructReturnsSelf: postConstructReturnsSelf,
    );
  }
}
