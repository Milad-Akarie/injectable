import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:injectable_generator/utils.dart';

import '../injectable_types.dart';

const _injectableImport = 'package:injectable/injectable.dart';
const _getItRefer = Reference('GetIt', 'package:get_it/get_it.dart');
const _ghRefer = Reference('gh');

class LibraryGenerator {
  late Set<DependencyConfig> _dependencies;
  final String _initializerName;
  final Uri? _targetFile;
  final bool _asExtension;

  LibraryGenerator({
    required List<DependencyConfig> dependencies,
    required String initializerName,
    Uri? targetFile,
    bool asExtension = false,
  })  : _initializerName = initializerName,
        _targetFile = targetFile,
        _asExtension = asExtension {
    _dependencies = sortDependencies(dependencies);
  }

  Library generate() {
    // if true use an awaited initializer
    final hasPreResolvedDeps = hasPreResolvedDependencies(_dependencies);

    // all environment keys used
    final environments = <String>{};
    // all register modules
    final modules = <ModuleConfig>{};
    _dependencies.forEach((dep) {
      environments.addAll(dep.environments);
      if (dep.moduleConfig != null) {
        modules.add(dep.moduleConfig!);
      }
    });

    final ignoreForFileComments = [
      '// ignore_for_file: unnecessary_lambdas',
      '// ignore_for_file: lines_longer_than_80_chars'
    ];
    final getInstanceRefer = refer(_asExtension ? 'this' : 'get');
    final intiMethod = Method(
      (b) => b
        ..docs.addAll([
          if (!_asExtension) ...ignoreForFileComments,
          '/// initializes the registration of provided dependencies inside of [GetIt]'
        ])
        ..returns = hasPreResolvedDeps
            ? TypeReference((b) => b
              ..symbol = 'Future'
              ..types.add(_getItRefer))
            : _getItRefer
        ..name = _initializerName
        ..modifier = hasPreResolvedDeps ? MethodModifier.async : null
        ..requiredParameters.addAll([
          if (!_asExtension)
            Parameter(
              (b) => b
                ..name = 'get'
                ..type = _getItRefer,
            )
        ])
        ..optionalParameters.addAll([
          Parameter((b) => b
            ..named = true
            ..name = 'environment'
            ..type = nullableRefer(
              'String',
              nullable: true,
            )),
          Parameter((b) => b
            ..named = true
            ..name = 'environmentFilter'
            ..type = nullableRefer(
              'EnvironmentFilter',
              url: _injectableImport,
              nullable: true,
            ))
        ])
        ..body = Block(
          (b) => b.statements.addAll([
            refer('GetItHelper', _injectableImport)
                .newInstance(
                  [
                    getInstanceRefer,
                    refer('environment'),
                    refer('environmentFilter'),
                  ],
                )
                .assignFinal('gh')
                .statement,
            ...modules.map((module) => refer('_\$${module.type.name}')
                .call([
                  if (moduleHasOverrides(
                    _dependencies.where((e) => e.moduleConfig == module),
                  ))
                    getInstanceRefer
                ])
                .assignFinal(toCamelCase(module.type.name))
                .statement),
            ..._dependencies.map((dep) {
              if (dep.injectableType == InjectableType.singleton) {
                return buildSingletonRegisterFun(dep);
              } else {
                return buildLazyRegisterFun(dep);
              }
            }),
            getInstanceRefer.returned.statement,
          ]),
        ),
    );

    return Library(
      (b) => b
        ..body.addAll(
          [
            ...environments.map((env) => Field(
                  (b) => b
                    ..name = '_$env'
                    ..type = refer('String')
                    ..assignment = literalString(env).code
                    ..modifier = FieldModifier.constant,
                )),

            if (_asExtension)
              Extension(
                (b) => b
                  ..docs.addAll([
                    ...ignoreForFileComments,
                    '/// an extension to register the provided dependencies inside of [GetIt]',
                  ])
                  ..name = 'GetItInjectableX'
                  ..on = _getItRefer
                  ..methods.add(intiMethod),
              ),
            if (!_asExtension) intiMethod,
            // build modules
            ...modules.map(
              (module) => _buildModule(
                module,
                _dependencies.where((e) => e.moduleConfig == module),
              ),
            )
          ],
        ),
    );
  }

  Class _buildModule(ModuleConfig module, Iterable<DependencyConfig> deps) {
    final abstractDeps = deps.where((d) => d.moduleConfig!.isAbstract);
    return Class((clazz) {
      clazz
        ..name = '_\$${module.type.name}'
        ..extend = typeRefer(module.type, _targetFile);
      // check weather we should have a getIt field inside of our module
      if (moduleHasOverrides(abstractDeps)) {
        clazz.fields.add(Field(
          (b) => b
            ..name = '_getIt'
            ..type = _getItRefer
            ..modifier = FieldModifier.final$,
        ));
        clazz.constructors.add(
          Constructor(
            (b) => b
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = '_getIt'
                    ..toThis = true,
                ),
              ),
          ),
        );
      }
      clazz.methods.addAll(abstractDeps.map(
        (dep) => Method(
          (b) => b
            ..annotations.add(refer('override'))
            ..name = dep.moduleConfig!.initializerName
            ..returns = typeRefer(dep.typeImpl, _targetFile)
            ..type = dep.moduleConfig!.isMethod ? null : MethodType.getter
            ..body = _buildInstance(dep,
                    getAsyncMethodName: '_getIt.getAsync',
                    getMethodName: '_getIt')
                .code,
        ),
      ));
    });
  }

  Code buildLazyRegisterFun(DependencyConfig dep) {
    var funcReferName;
    Map<String, Reference> factoryParams = {};
    final hasAsyncDep = hasAsyncDependency(dep, _dependencies);
    final isOrHasAsyncDep = dep.isAsync || hasAsyncDep;

    if (dep.injectableType == InjectableType.factory) {
      final hasFactoryParams = dep.dependencies.any((d) => d.isFactoryParam);
      if (hasFactoryParams) {
        funcReferName = isOrHasAsyncDep ? 'factoryParamAsync' : 'factoryParam';
        factoryParams.addAll(_resolveFactoryParams(dep));
      } else {
        funcReferName = isOrHasAsyncDep ? 'factoryAsync' : 'factory';
      }
    } else if (dep.injectableType == InjectableType.lazySingleton) {
      funcReferName = isOrHasAsyncDep ? 'lazySingletonAsync' : 'lazySingleton';
    }
    throwIf(funcReferName == null, 'Injectable type is not supported');

    final registerExpression = _ghRefer.property(funcReferName).call([
      Method(
        (b) => b
          ..lambda = true
          ..modifier = hasAsyncDep ? MethodModifier.async : null
          ..requiredParameters.addAll(
            factoryParams.keys.map(
              (name) => Parameter((b) => b.name = name),
            ),
          )
          ..body = dep.isFromModule
              ? _buildInstanceForModule(dep).code
              : _buildInstance(dep).code,
      ).closure
    ], {
      if (dep.instanceName != null)
        'instanceName': literalString(dep.instanceName!),
      if (dep.environments.isNotEmpty == true)
        'registerFor': literalSet(
          dep.environments.map((e) => refer('_$e')),
        ),
      if (dep.preResolve == true) 'preResolve': literalBool(true),
      if (dep.disposeFunction != null)
        'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!)
    }, [
      typeRefer(dep.type, _targetFile),
      ...factoryParams.values.map((p) => p.type)
    ]);
    return dep.preResolve
        ? registerExpression.awaited.statement
        : registerExpression.statement;
  }

  Map<String, Reference> _resolveFactoryParams(DependencyConfig dep) {
    final params = <String, Reference>{};
    dep.dependencies.where((d) => d.isFactoryParam).forEach((d) {
      params[d.paramName] = typeRefer(d.type, _targetFile);
    });
    if (params.length < 2) {
      params['_'] = refer('dynamic');
    }
    return params;
  }

  Code buildSingletonRegisterFun(DependencyConfig dep) {
    var funcReferName;
    final hasAsyncDep = hasAsyncDependency(dep, _dependencies);
    if (dep.isAsync || hasAsyncDep) {
      funcReferName = 'singletonAsync';
    } else if (dep.dependsOn.isNotEmpty) {
      funcReferName = 'singletonWithDependencies';
    } else {
      funcReferName = 'singleton';
    }

    final instanceBuilder =
        dep.isFromModule ? _buildInstanceForModule(dep) : _buildInstance(dep);
    final registerExpression = _ghRefer.property(funcReferName).call([
      Method((b) => b
        ..lambda = true
        ..modifier = hasAsyncDep ? MethodModifier.async : null
        ..body = instanceBuilder.code).closure
    ], {
      if (dep.instanceName != null)
        'instanceName': literalString(dep.instanceName!),
      if (dep.dependsOn.isNotEmpty)
        'dependsOn': literalList(
          dep.dependsOn.map(
            (e) => typeRefer(e, _targetFile),
          ),
        ),
      if (dep.environments.isNotEmpty)
        'registerFor': literalSet(
          dep.environments.map((e) => refer('_$e')),
        ),
      if (dep.signalsReady != null)
        'signalsReady': literalBool(dep.signalsReady!),
      if (dep.preResolve == true) 'preResolve': literalBool(true),
      if (dep.disposeFunction != null)
        'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!)
    }, [
      typeRefer(dep.type, _targetFile)
    ]);

    return dep.preResolve
        ? registerExpression.awaited.statement
        : registerExpression.statement;
  }

  Expression _buildInstance(
    DependencyConfig dep, {
    String? getAsyncMethodName,
    String? getMethodName,
  }) {
    final positionalParams = dep.positionalDependencies.map(
      (iDep) => _buildParamAssignment(iDep,
          getAsyncReferName: getAsyncMethodName, getReferName: getMethodName),
    );

    final namedParams = Map.fromEntries(
      dep.namedDependencies.map(
        (iDep) => MapEntry(
          iDep.paramName,
          _buildParamAssignment(iDep,
              getAsyncReferName: getAsyncMethodName,
              getReferName: getMethodName),
        ),
      ),
    );

    final ref = typeRefer(dep.typeImpl, _targetFile);
    if (dep.constructorName?.isNotEmpty == true) {
      return ref
          .newInstanceNamed(
            dep.constructorName!,
            positionalParams,
            namedParams,
          )
          .expression;
    } else {
      return ref.newInstance(positionalParams, namedParams).expression;
    }
  }

  Expression _buildInstanceForModule(DependencyConfig dep) {
    final module = dep.moduleConfig!;
    if (!module.isMethod) {
      return refer(
        toCamelCase(module.type.name),
      ).property(module.initializerName).expression;
    }

    return refer(toCamelCase(module.type.name))
        .newInstanceNamed(
          module.initializerName,
          dep.positionalDependencies.map(
            (iDep) => _buildParamAssignment(iDep),
          ),
          Map.fromEntries(
            dep.namedDependencies.map(
              (iDep) => MapEntry(
                iDep.paramName,
                _buildParamAssignment(iDep),
              ),
            ),
          ),
        )
        .expression;
  }

  Expression _getDisposeFunctionAssignment(
      DisposeFunctionConfig disposeFunction) {
    if (disposeFunction.isInstance) {
      return Method((b) => b
            ..requiredParameters.add(Parameter((b) => b.name = 'i'))
            ..body = refer('i').property(disposeFunction.name).call([]).code)
          .closure;
    } else {
      return typeRefer(disposeFunction.importableType!, _targetFile);
    }
  }

  Expression _buildParamAssignment(
    InjectedDependency iDep, {
    String? getAsyncReferName,
    String? getReferName,
  }) {
    if (iDep.isFactoryParam) {
      return refer(iDep.paramName);
    }
    getAsyncReferName ??= _asExtension ? 'getAsync' : 'get.getAsync';
    getReferName ??= 'get';
    final isAsync = isAsyncOrHasAsyncDependency(iDep, _dependencies);
    final expression =
        refer(isAsync ? getAsyncReferName : getReferName).call([], {
      if (iDep.instanceName != null)
        'instanceName': literalString(iDep.instanceName!),
    }, [
      typeRefer(iDep.type, _targetFile, false),
    ]);
    return isAsync ? expression.awaited : expression;
  }
}

bool moduleHasOverrides(Iterable<DependencyConfig> deps) {
  return deps.where((d) => d.moduleConfig?.isAbstract == true).any(
        (d) => d.dependencies.isNotEmpty == true,
      );
}
