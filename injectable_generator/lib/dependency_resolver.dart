import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

const TypeChecker namedChecker = TypeChecker.fromRuntime(Named);
const TypeChecker singletonChecker = TypeChecker.fromRuntime(Singleton);
const TypeChecker envChecker = TypeChecker.fromRuntime(Environment);
const TypeChecker registerAsChecker = TypeChecker.fromRuntime(RegisterAs);
const TypeChecker preResolveChecker = TypeChecker.fromRuntime(PreResolve);
const TypeChecker factoryParamChecker = TypeChecker.fromRuntime(FactoryParam);
const TypeChecker constructorChecker = TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  Element _annotatedElement;
  final _dep = DependencyConfig();
  final Resolver _resolver;
  final Map<String, String> _typeArgsMap = {};

  DependencyResolver(this._resolver);

  Future<DependencyConfig> resolve(Element element) {
    _annotatedElement = element;
    final import = getImport(element);
    if (import != null) {
      _dep.imports.add(import);
    }
    return _resolveActualType(_annotatedElement);
  }

  Future<DependencyConfig> resolveModuleMember(ClassElement moduleClazz,
                                               ExecutableElement executableElement,) async {
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

    throwBoxedIf(returnType.element is! ClassElement,
        '${returnType.getDisplayString()} is not a class element');

    await _checkForParameterizedTypes(returnType);
    final registerModuleItem = RegisterModuleItem();
    registerModuleItem.moduleName = moduleClazz.name;
    registerModuleItem.import = getImport(moduleClazz);

    if (executableElement is MethodElement) {
      throwBoxedIf(executableElement.parameters.length > 2,
          'Error generating [$returnType]! Max number of factory params is 2');
      registerModuleItem.isMethod = true;

      for (var param in executableElement.parameters) {
        await _resolveAndAddImport(param.type.element);
        await _checkForParameterizedTypes(param.type);
        registerModuleItem.params[param.name] = param.type.getDisplayString();
      }
    }

    ClassElement clazz;
    if (executableElement.isAbstract) {
      clazz = returnType.element;
      registerModuleItem.isAbstract = true;
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
    registerModuleItem.name = executableElement.name;
    _dep.moduleConfig = registerModuleItem;
    await _resolveAndAddImport(clazz);
    return _resolveActualType(clazz, typeName);
  }

  Future<DependencyConfig> _resolveActualType(ClassElement clazz,
      [String typeName]) async {
    _dep.type = typeName ?? clazz.name;
    _dep.bindTo = typeName ?? clazz.name;

    var inlineEnv;
    final registerAsAnnotation =
    registerAsChecker.firstAnnotationOf(_annotatedElement);
    if (registerAsAnnotation != null) {
      ConstantReader registerAsReader = ConstantReader(registerAsAnnotation);
      final abstractType = registerAsReader
          .peek('abstractType')
          .typeValue;
      final abstractChecker = TypeChecker.fromStatic(abstractType);

      final abstractSubtype = clazz.allSupertypes.firstWhere(
          (type) => abstractChecker.isExactly(type.element), orElse: () {
        throwBoxed(
            '[${clazz.name}] is not a subtype of [${abstractType.getDisplayString()}]');
        return null;
      });

      _dep.type = abstractSubtype.getDisplayString();

      inlineEnv = registerAsReader
          .peek('env')
          ?.stringValue;

      _dep.bindTo = clazz.name;
      await _resolveAndAddImport(abstractSubtype.element);
      await _checkForParameterizedTypes(abstractSubtype);
    }

    _dep.environment = inlineEnv ??
        envChecker
            .firstAnnotationOfExact(_annotatedElement, throwOnUnresolved: false)
            ?.getField('name')
            ?.toStringValue();

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

    final singletonAnnotation = singletonChecker
        .firstAnnotationOf(_annotatedElement, throwOnUnresolved: false);
    if (singletonAnnotation != null) {
      if (singletonAnnotation.getField('_lazy').toBoolValue()) {
        _dep.injectableType = InjectableType.lazySingleton;
      } else {
        _dep.injectableType = InjectableType.singleton;
        _dep.dependsOn = singletonAnnotation
            .getField('dependsOn')
            ?.toListValue()
            ?.map<String>((v) => v.toTypeValue().getDisplayString())
            ?.toList();
      }

      _dep.signalsReady =
          singletonAnnotation.getField('signalsReady')?.toBoolValue();
    } else {
      _dep.injectableType = InjectableType.factory;
    }

    ExecutableElement constructor;
    if (_dep.moduleConfig == null || _dep.moduleConfig.isAbstract) {
      final possibleFactories = <ExecutableElement>[
        ...clazz.methods.where((m) => m.isStatic),
        ...clazz.constructors
      ];

      constructor = possibleFactories
          .firstWhere((m) => constructorChecker.hasAnnotationOf(m), orElse: () {
        throwBoxedIf(clazz.isAbstract,
            '''[${clazz.name}] is abstract and can not be registered directly!
                \n if it has a factory or a create method annotate it with @factoryMethod''');
        return clazz.unnamedConstructor;
      });
    }
    if (constructor != null) {
      _dep.isAsync = constructor.returnType.isDartAsyncFuture;
      _dep.constructorName = constructor.name;

      for (ParameterElement param in constructor.parameters) {
        final namedAnnotation = namedChecker.firstAnnotationOf(param);
        final instanceName = namedAnnotation
                ?.getField('type')
                ?.toTypeValue()
                ?.getDisplayString() ??
            namedAnnotation?.getField('name')?.toStringValue();
        await _resolveAndAddImport(param.type.element);
        await _checkForParameterizedTypes(param.type);

        var typeName = param.type.getDisplayString();
        if (param.type is TypeParameterType) {
          typeName = _typeArgsMap[param.type.getDisplayString()];
          throwBoxedIf(typeName == null,
              'Error generating [${clazz.name}]! Can not resolve dependency of type ${param.type.getDisplayString()}');
        }

        _dep.dependencies.add(InjectedDependency(
          type: typeName,
          name: instanceName,
          isFactoryParam: _dep.moduleConfig == null &&
              factoryParamChecker.hasAnnotationOf(param),
          paramName: param.name,
          isPositional: param.isPositional,
        ));

        throwBoxedIf(
            _dep.dependencies.where((d) => d.isFactoryParam).length > 2,
            'Error generating [${clazz.name}]! Max number of factory params is 2');
      }
    }

    throwBoxedIf(
        _dep.injectableType != InjectableType.factory &&
            (_dep.dependencies.where((d) => d.isFactoryParam).isNotEmpty ||
                _dep.moduleConfig?.params?.isNotEmpty == true),
        'Error generating [${clazz.name}]! only factories can have parameters');
    return _dep;
  }

  Future<String> _resolveLibImport(Element element) async {
    if (element.source?.isInSystemLibrary == true) {
      return null;
    }
    final assetId = await _resolver.assetIdForElement(element);
    final lib = await _resolver.findLibraryByName(assetId.package);
    if (lib != null) {
      return getImport(lib);
    } else {
      return getImport(element);
    }
  }

  Future<void> _checkForParameterizedTypes(DartType paramType) async {
    if (paramType is ParameterizedType) {
      for (DartType type in paramType.typeArguments) {
        await _checkForParameterizedTypes(type);
        if (type.element.source != null) {
          await _resolveAndAddImport(type.element);
        }
      }
      ;
    }
  }

  Future<void> _resolveAndAddImport(Element element) async {
    final import = await _resolveLibImport(element);
    if (import != null) {
      _dep.imports.add(import);
    }
  }
}
