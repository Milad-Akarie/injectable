import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'dependency_config.dart';
import 'injectable_types.dart';

const TypeChecker namedChecker = const TypeChecker.fromRuntime(Named);
const TypeChecker singletonChecker = const TypeChecker.fromRuntime(Singleton);
const TypeChecker envChecker = const TypeChecker.fromRuntime(Environment);
const TypeChecker bindChecker = const TypeChecker.fromRuntime(RegisterAs);
const TypeChecker asInstanceChecker = const TypeChecker.fromRuntime(AsInstance);

const TypeChecker constructorChecker =
    const TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  Element _annotatedElement;
  final _dep = DependencyConfig();
  final Resolver _resolver;

  DependencyResolver(this._resolver);

  Future<DependencyConfig> resolve(Element element) {
    _annotatedElement = element;
    final import = getImport(element);
    if (import != null) {
      _dep.imports.add(import);
    }
    return _resolve(_annotatedElement);
  }

  Future<DependencyConfig> resolveAccessor(
      ClassElement moduleClazz, PropertyAccessorElement accessorElement) async {
    _annotatedElement = accessorElement;
    final returnType = accessorElement.returnType;
    String typeName = returnType.getDisplayString();
    if (returnType.element is! ClassElement) {
      throwBoxed('${returnType.getDisplayString()} is not a class element');
      return null;
    } else {
      await _checkForParameterizedTypes(returnType);
      final registerModuleItem = RegisterModuleItem();
      registerModuleItem.moduleName = moduleClazz.name;
      registerModuleItem.import = getImport(moduleClazz);
      ClassElement clazz;
      if (accessorElement.isAbstract) {
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

      registerModuleItem.name = accessorElement.name;
      _dep.moduleConfig = registerModuleItem;
      await _resolveAndAddImport(clazz);
      return _resolve(clazz, typeName);
    }
  }

  Future<DependencyConfig> _resolve(ClassElement clazz,
      [String typeName]) async {
    _dep.type = typeName ?? clazz.name;
    _dep.bindTo = typeName ?? clazz.name;

    var inlineEnv;
    final bindAnnotation = bindChecker.firstAnnotationOf(_annotatedElement);
    if (bindAnnotation != null) {
      ConstantReader bindReader = ConstantReader(bindAnnotation);
      final abstractType = bindReader.peek('abstractType')?.typeValue;
      inlineEnv = bindReader.peek('env')?.stringValue;
      _dep.type = abstractType.getDisplayString();
      _dep.bindTo = clazz.name;
      await _resolveAndAddImport(abstractType.element);
    }

    _dep.environment = inlineEnv ??
        envChecker
            .firstAnnotationOfExact(_annotatedElement, throwOnUnresolved: false)
            ?.getField('name')
            ?.toStringValue();

    _dep.asInstance = asInstanceChecker.hasAnnotationOfExact(_annotatedElement);
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
    if (_dep.moduleConfig == null || _dep.moduleConfig.isAbstract) {
      final possibleFactories = <ExecutableElement>[
        ...clazz.methods.where((m) => m.isStatic),
        ...clazz.constructors
      ];

      constructor = possibleFactories
          .firstWhere((m) => constructorChecker.hasAnnotationOf(m), orElse: () {
        throwBoxedIf(clazz.isAbstract,
            '''[${_annotatedElement.name}] is abstract and can not be registered directly!
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

        _dep.dependencies.add(InjectedDependency(
          type: param.type.getDisplayString(),
          name: instanceName,
          paramName: param.isPositional ? null : param.name,
        ));
      }
    }

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
