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

const TypeChecker constructorChecker =
    const TypeChecker.fromRuntime(FactoryMethod);

class DependencyResolver {
  final Element _annotatedElement;
  final _dep = DependencyConfig();

  DependencyResolver(this._annotatedElement) {}

  Future<DependencyConfig> resolve(Resolver resolver) {
    _dep.imports.add(getImport(_annotatedElement));
    return _resolve(_annotatedElement, resolver);
  }

  Future<DependencyConfig> resolveFromAccessor(
      ClassElement moduleClazz, Resolver resolver) async {
    final PropertyAccessorElement accessorElement = _annotatedElement;
    final returnType = accessorElement.returnType;

    if (returnType.element is! ClassElement) {
      throwBoxed('${returnType.getDisplayString()} is not a class element');
      return null;
    } else {
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
          registerModuleItem.isAsync = true;
        } else {
          clazz = returnType.element;
        }
      }

      registerModuleItem.name = accessorElement.name;
      _dep.moduleConfig = registerModuleItem;

      final import = await _resolveLibImport(clazz, resolver);
      _dep.imports.add(import);
      return _resolve(clazz, resolver);
    }
  }

  Future<DependencyConfig> _resolve(
      ClassElement clazz, Resolver resolver) async {
    _dep.type = clazz.name;
    _dep.bindTo = clazz.name;

    var inlineEnv;
    final bindAnnotation = bindChecker.firstAnnotationOf(_annotatedElement);
    if (bindAnnotation != null) {
      ConstantReader bindReader = ConstantReader(bindAnnotation);
      final abstractType = bindReader.peek('abstractType')?.typeValue;
      inlineEnv = bindReader.peek('env')?.stringValue;
      _dep.type = abstractType.getDisplayString();
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
    if (_dep.moduleConfig == null || _dep.moduleConfig.isAbstract) {
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

      for (ParameterElement param in constructor.parameters) {
        final namedAnnotation = namedChecker.firstAnnotationOf(param);
        final instanceName = namedAnnotation
                ?.getField('type')
                ?.toTypeValue()
                ?.getDisplayString() ??
            namedAnnotation?.getField('name')?.toStringValue();
        final import = await _resolveLibImport(param.type.element, resolver);
        _dep.dependencies.add(InjectedDependency(
          type: param.type.getDisplayString(),
          name: instanceName,
          paramName: param.isPositional ? null : param.name,
          import: import,
        ));
      }
    }

    return _dep;
  }

  Future<String> _resolveLibImport(Element element, Resolver resolver) async {
    final assetId = await resolver.assetIdForElement(element);
    final lib = await resolver.findLibraryByName(assetId.package);
    if (lib != null) {
      return getImport(lib);
    } else {
      return getImport(element);
    }
  }
}
