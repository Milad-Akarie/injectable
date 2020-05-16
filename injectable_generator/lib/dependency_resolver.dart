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
const TypeChecker injectableChecker = TypeChecker.fromRuntime(Injectable);

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

    await _checkForParameterizedTypes(returnType);

    _dep.moduleName = moduleClazz.name;
    _dep.initializerName = executableElement.name;
    _dep.imports.add(getImport(moduleClazz));

    ExecutableElement executableModuleMember;
    if (executableElement is MethodElement) {
      _dep.isModuleMethod = true;

      if (!executableElement.isAbstract) {
        executableModuleMember = executableElement;
      } else {
        throwIf(
          executableElement.parameters.isNotEmpty,
          'Abstract methods can not have injectable or factory paramters',
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
    await _resolveAndAddImport(clazz);
    return _resolveActualType(clazz, typeName, executableModuleMember);
  }

  Future<DependencyConfig> _resolveActualType(
    ClassElement clazz, [
    String typeName,
    ExecutableElement executbaleModuleMemeber,
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
      inlineEnv = injectable.peek('env')?.stringValue;
    }

    if (abstractType == null) {
      final registerAsAnnotation =
          registerAsChecker.firstAnnotationOf(_annotatedElement);
      if (registerAsAnnotation != null) {
        final registerAsReader = ConstantReader(registerAsAnnotation);
        abstractType = registerAsReader.peek('abstractType').typeValue;
        inlineEnv = registerAsReader.peek('env')?.stringValue;
      }
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

    ExecutableElement excutableInitilizer;

    if (executbaleModuleMemeber != null) {
      excutableInitilizer = executbaleModuleMemeber;
    } else if (!_dep.isFromModule || _dep.isAbstract) {
      final possibleFactories = <ExecutableElement>[
        ...clazz.methods.where((m) => m.isStatic),
        ...clazz.constructors
      ];

      excutableInitilizer = possibleFactories.firstWhere(
          (m) => constructorChecker.hasAnnotationOfExact(m), orElse: () {
        throwIf(
          clazz.isAbstract,
          '''[${clazz.name}] is abstract and can not be registered directly!
           if it has a factory or a create method annotate it with @factoryMethod''',
          element: clazz,
        );
        return clazz.unnamedConstructor;
      });
      _dep.isAsync = excutableInitilizer.returnType.isDartAsyncFuture;
    }

    if (excutableInitilizer != null) {
      _dep.constructorName = excutableInitilizer.name;
      for (ParameterElement param in excutableInitilizer.parameters) {
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
        'Module dependecies with factory params must have custom initilaizers',
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

  Future<String> _resolveLibImport(Element element) async {
    if (element == null ||
        element.source == null ||
        isCoreDartType(element.source)) {
      return null;
    }
    //if element from a system library but not from dart:core
    if (element.source.isInSystemLibrary) {
      return getImport(element);
    }
    final assetId = await _resolver.assetIdForElement(element);

    final toBeImported =
        await _resolver.findLibraryByName(assetId.package) ?? element;
    return getImport(toBeImported);
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
