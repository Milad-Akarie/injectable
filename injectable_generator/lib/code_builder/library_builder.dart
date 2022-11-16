import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:injectable_generator/utils.dart';
import 'package:collection/collection.dart';
import '../injectable_types.dart';

const _injectableImport = 'package:injectable/injectable.dart';
const _getItImport = 'package:get_it/get_it.dart';
const _getItRefer = Reference('GetIt', _getItImport);
const _ghRefer = Reference('gh');

class LibraryGenerator {
  late Set<DependencyConfig> _dependencies;
  final String initializerName;
  final Uri? targetFile;
  final bool asExtension;

  LibraryGenerator({
    required List<DependencyConfig> dependencies,
    required this.initializerName,
    this.targetFile,
    this.asExtension = false,
  }) {
    _dependencies = sortDependencies(dependencies);
  }

  Library generate() {
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

    final scopes = groupBy<DependencyConfig, String?>(_dependencies, (d) => d.scope);

    final initMethods = <Method>[];
    for (final name in scopes.keys) {
      final scopeDeps = scopes[name];
      if (scopeDeps != null) {
        initMethods.add(
          InitMethodGenerator(
            scopeDependencies: scopeDeps,
            allDependencies: _dependencies,
            initializerName: name == null ? initializerName : 'init${capitalize(name)}Scope',
            asExtension: asExtension,
            scopeName: name,
          ).generate(),
        );
      }
    }

    return Library(
      (b) => b
        ..body.addAll(
          [
            ...environments.map(
              (env) => Field(
                (b) => b
                  ..name = '_$env'
                  ..type = refer('String')
                  ..assignment = literalString(env).code
                  ..modifier = FieldModifier.constant,
              ),
            ),
            if (asExtension)
              Extension(
                (b) => b
                  ..docs.addAll([
                    '// ignore_for_file: unnecessary_lambdas',
                    '// ignore_for_file: lines_longer_than_80_chars',
                  ])
                  ..name = 'GetItInjectableX'
                  ..on = _getItRefer
                  ..methods.addAll(initMethods),
              )
            else
              ...initMethods,
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
        ..extend = typeRefer(module.type, targetFile);
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
            ..returns = typeRefer(dep.typeImpl, targetFile)
            ..type = dep.moduleConfig!.isMethod ? null : MethodType.getter
            ..body = _buildInstance(dep, getAsyncMethodName: '_getIt.getAsync', getMethodName: '_getIt').code,
        ),
      ));
    });
  }

  Code buildLazyRegisterFun(DependencyConfig dep) {
    var funcReferName;
    Map<String, Reference> factoryParams = {};
    final hasAsyncDep = hasAsyncDependency(dep, _dependencies);
    final isAsyncOrHasAsyncDep = dep.isAsync || hasAsyncDep;

    if (dep.injectableType == InjectableType.factory) {
      final hasFactoryParams = dep.dependencies.any((d) => d.isFactoryParam);
      if (hasFactoryParams) {
        funcReferName = isAsyncOrHasAsyncDep ? 'factoryParamAsync' : 'factoryParam';
        factoryParams.addAll(_resolveFactoryParams(dep));
      } else {
        funcReferName = isAsyncOrHasAsyncDep ? 'factoryAsync' : 'factory';
      }
    } else if (dep.injectableType == InjectableType.lazySingleton) {
      funcReferName = isAsyncOrHasAsyncDep ? 'lazySingletonAsync' : 'lazySingleton';
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
          ..body = dep.isFromModule ? _buildInstanceForModule(dep).code : _buildInstance(dep).code,
      ).closure
    ], {
      if (dep.instanceName != null) 'instanceName': literalString(dep.instanceName!),
      if (dep.environments.isNotEmpty == true)
        'registerFor': literalSet(
          dep.environments.map((e) => refer('_$e')),
        ),
      if (dep.preResolve == true) 'preResolve': literalBool(true),
      if (dep.disposeFunction != null) 'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!)
    }, [
      typeRefer(dep.type, targetFile),
      ...factoryParams.values.map((p) => p.type)
    ]);
    return dep.preResolve ? registerExpression.awaited.statement : registerExpression.statement;
  }

  Map<String, Reference> _resolveFactoryParams(DependencyConfig dep) {
    final params = <String, Reference>{};
    dep.dependencies.where((d) => d.isFactoryParam).forEach((d) {
      params[d.paramName] = typeRefer(d.type, targetFile);
    });
    if (params.length < 2) {
      params['_'] = refer('dynamic');
    }
    return params;
  }

  Code buildSingletonRegisterFun(DependencyConfig dep) {
    var funcReferName;
    var asFactory = true;
    final hasAsyncDep = hasAsyncDependency(dep, _dependencies);
    if (dep.isAsync || hasAsyncDep) {
      funcReferName = 'singletonAsync';
    } else if (dep.dependsOn.isNotEmpty) {
      funcReferName = 'singletonWithDependencies';
    } else {
      asFactory = false;
      funcReferName = 'singleton';
    }

    final instanceBuilder = dep.isFromModule ? _buildInstanceForModule(dep) : _buildInstance(dep);
    final registerExpression = _ghRefer.property(funcReferName).call([
      asFactory
          ? Method((b) => b
            ..lambda = true
            ..modifier = hasAsyncDep ? MethodModifier.async : null
            ..body = instanceBuilder.code).closure
          : instanceBuilder
    ], {
      if (dep.instanceName != null) 'instanceName': literalString(dep.instanceName!),
      if (dep.dependsOn.isNotEmpty)
        'dependsOn': literalList(
          dep.dependsOn.map(
            (e) => typeRefer(e, targetFile),
          ),
        ),
      if (dep.environments.isNotEmpty)
        'registerFor': literalSet(
          dep.environments.map((e) => refer('_$e')),
        ),
      if (dep.signalsReady != null) 'signalsReady': literalBool(dep.signalsReady!),
      if (dep.preResolve == true) 'preResolve': literalBool(true),
      if (dep.disposeFunction != null) 'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!)
    }, [
      typeRefer(dep.type, targetFile)
    ]);

    return dep.preResolve ? registerExpression.awaited.statement : registerExpression.statement;
  }

  Expression _buildInstance(
    DependencyConfig dep, {
    String? getAsyncMethodName,
    String? getMethodName,
  }) {
    final positionalParams = dep.positionalDependencies.map(
      (iDep) => _buildParamAssignment(iDep, getAsyncReferName: getAsyncMethodName, getReferName: getMethodName),
    );

    final namedParams = Map.fromEntries(
      dep.namedDependencies.map(
        (iDep) => MapEntry(
          iDep.paramName,
          _buildParamAssignment(iDep, getAsyncReferName: getAsyncMethodName, getReferName: getMethodName),
        ),
      ),
    );

    final ref = typeRefer(dep.typeImpl, targetFile);
    if (dep.constructorName?.isNotEmpty == true) {
      return ref.newInstanceNamed(
        dep.constructorName!,
        positionalParams,
        namedParams,
      );
    } else {
      return ref.newInstance(positionalParams, namedParams);
    }
  }

  Expression _buildInstanceForModule(DependencyConfig dep) {
    final module = dep.moduleConfig!;
    if (!module.isMethod) {
      return refer(
        toCamelCase(module.type.name),
      ).property(module.initializerName);
    }

    return refer(toCamelCase(module.type.name)).newInstanceNamed(
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
    );
  }

  Expression _getDisposeFunctionAssignment(DisposeFunctionConfig disposeFunction) {
    if (disposeFunction.isInstance) {
      return Method((b) => b
        ..requiredParameters.add(Parameter((b) => b.name = 'i'))
        ..body = refer('i').property(disposeFunction.name).call([]).code).closure;
    } else {
      return typeRefer(disposeFunction.importableType!, targetFile);
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
    getAsyncReferName ??= asExtension ? 'getAsync' : 'get.getAsync';
    getReferName ??= 'get';
    final isAsync = isAsyncOrHasAsyncDependency(iDep, _dependencies);
    final expression = refer(isAsync ? getAsyncReferName : getReferName).call([], {
      if (iDep.instanceName != null) 'instanceName': literalString(iDep.instanceName!),
    }, [
      typeRefer(iDep.type, targetFile, false),
    ]);
    return isAsync ? expression.awaited : expression;
  }
}

class InitMethodGenerator {
  late Set<DependencyConfig> allDependencies, _scopeDependencies;
  final String initializerName;
  final Uri? targetFile;
  final bool asExtension;
  final String? scopeName;

  InitMethodGenerator({
    required List<DependencyConfig> scopeDependencies,
    required this.allDependencies,
    required this.initializerName,
    this.targetFile,
    this.asExtension = false,
    this.scopeName,
  }) {
    _scopeDependencies = sortDependencies(scopeDependencies);
  }

  Method generate() {
    // if true use an awaited initializer
    final hasPreResolvedDeps = hasPreResolvedDependencies(_scopeDependencies);

    // all register modules
    final modules = <ModuleConfig>{};
    _scopeDependencies.forEach((dep) {
      if (dep.moduleConfig != null) {
        modules.add(dep.moduleConfig!);
      }
    });

    final getInstanceRefer = refer(asExtension ? 'this' : 'get');

    final ghStatements = [
      ...modules.map((module) => refer('_\$${module.type.name}')
          .call([
            if (moduleHasOverrides(
              allDependencies.where((e) => e.moduleConfig == module),
            ))
              getInstanceRefer
          ])
          .assignFinal(toCamelCase(module.type.name))
          .statement),
      ..._scopeDependencies.map((dep) {
        if (dep.injectableType == InjectableType.singleton) {
          return buildSingletonRegisterFun(dep);
        } else {
          return buildLazyRegisterFun(dep);
        }
      }),
    ];
    return Method(
      (b) => b
        ..docs.addAll([
          if (!asExtension && scopeName == null) ...[
            '// ignore_for_file: unnecessary_lambdas',
            '// ignore_for_file: lines_longer_than_80_chars'
          ],
          '/// initializes the registration of ${scopeName ?? 'main'}-scope dependencies inside of [GetIt]'
        ])
        ..modifier = hasPreResolvedDeps ? MethodModifier.async : null
        ..returns = hasPreResolvedDeps
            ? TypeReference((b) => b
              ..symbol = 'Future'
              ..types.add(_getItRefer))
            : _getItRefer
        ..name = initializerName
        ..requiredParameters.addAll([
          if (!asExtension)
            Parameter(
              (b) => b
                ..name = 'get'
                ..type = _getItRefer,
            )
        ])
        ..optionalParameters.addAll([
          if (scopeName == null) ...[
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
          ] else
            Parameter((b) => b
              ..named = true
              ..name = 'dispose'
              ..type = nullableRefer(
                'ScopeDisposeFunc',
                url: _getItImport,
                nullable: true,
              )),
        ])
        ..body = Block(
          (b) => b.statements.addAll([
            if (scopeName != null)
              refer('GetItHelper', _injectableImport).newInstance([getInstanceRefer])
                  .property('initScope${hasPreResolvedDeps ? 'Async' : ''}')
                  .call([
                    literalString(scopeName!)
                  ], {
                    'dispose': refer('dispose'),
                    'init': Method((b) => b
                      ..modifier = hasPreResolvedDeps ? MethodModifier.async : null
                      ..requiredParameters.add(Parameter(
                        (b) => b
                          ..name = 'gh'
                          ..type = refer('GetItHelper', _injectableImport),
                      ))
                      ..body = Block(
                        (b) => b.statements.addAll(ghStatements),
                      )).closure
                  })
                  .returned
                  .statement
            else ...[
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
              ...ghStatements,
              getInstanceRefer.returned.statement,
            ],
          ]),
        ),
    );
  }

  Code buildLazyRegisterFun(DependencyConfig dep) {
    var funcReferName;
    Map<String, Reference> factoryParams = {};
    final hasAsyncDep = hasAsyncDependency(dep, _scopeDependencies);
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
          ..body = dep.isFromModule ? _buildInstanceForModule(dep).code : _buildInstance(dep).code,
      ).closure
    ], {
      if (dep.instanceName != null) 'instanceName': literalString(dep.instanceName!),
      if (dep.environments.isNotEmpty == true)
        'registerFor': literalSet(
          dep.environments.map((e) => refer('_$e')),
        ),
      if (dep.preResolve == true) 'preResolve': literalBool(true),
      if (dep.disposeFunction != null) 'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!)
    }, [
      typeRefer(dep.type, targetFile),
      ...factoryParams.values.map((p) => p.type)
    ]);
    return dep.preResolve ? registerExpression.awaited.statement : registerExpression.statement;
  }

  Map<String, Reference> _resolveFactoryParams(DependencyConfig dep) {
    final params = <String, Reference>{};
    dep.dependencies.where((d) => d.isFactoryParam).forEach((d) {
      params[d.paramName] = typeRefer(d.type, targetFile);
    });
    if (params.length < 2) {
      params['_'] = refer('dynamic');
    }
    return params;
  }

  Code buildSingletonRegisterFun(DependencyConfig dep) {
    var funcReferName;
    var asFactory = true;
    final hasAsyncDep = hasAsyncDependency(dep, _scopeDependencies);
    if (dep.isAsync || hasAsyncDep) {
      funcReferName = 'singletonAsync';
    } else if (dep.dependsOn.isNotEmpty) {
      funcReferName = 'singletonWithDependencies';
    } else {
      asFactory = false;
      funcReferName = 'singleton';
    }

    final instanceBuilder = dep.isFromModule ? _buildInstanceForModule(dep) : _buildInstance(dep);
    final registerExpression = _ghRefer.property(funcReferName).call([
      asFactory
          ? Method((b) => b
            ..lambda = true
            ..modifier = hasAsyncDep ? MethodModifier.async : null
            ..body = instanceBuilder.code).closure
          : instanceBuilder
    ], {
      if (dep.instanceName != null) 'instanceName': literalString(dep.instanceName!),
      if (dep.dependsOn.isNotEmpty)
        'dependsOn': literalList(
          dep.dependsOn.map(
            (e) => typeRefer(e, targetFile),
          ),
        ),
      if (dep.environments.isNotEmpty)
        'registerFor': literalSet(
          dep.environments.map((e) => refer('_$e')),
        ),
      if (dep.signalsReady != null) 'signalsReady': literalBool(dep.signalsReady!),
      if (dep.preResolve == true) 'preResolve': literalBool(true),
      if (dep.disposeFunction != null) 'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!)
    }, [
      typeRefer(dep.type, targetFile)
    ]);

    return dep.preResolve ? registerExpression.awaited.statement : registerExpression.statement;
  }

  Expression _buildInstance(
    DependencyConfig dep, {
    String? getAsyncMethodName,
    String? getMethodName,
  }) {
    final positionalParams = dep.positionalDependencies.map(
      (iDep) => _buildParamAssignment(iDep, getAsyncReferName: getAsyncMethodName, getReferName: getMethodName),
    );

    final namedParams = Map.fromEntries(
      dep.namedDependencies.map(
        (iDep) => MapEntry(
          iDep.paramName,
          _buildParamAssignment(iDep, getAsyncReferName: getAsyncMethodName, getReferName: getMethodName),
        ),
      ),
    );

    final ref = typeRefer(dep.typeImpl, targetFile);
    if (dep.constructorName?.isNotEmpty == true) {
      return ref.newInstanceNamed(
        dep.constructorName!,
        positionalParams,
        namedParams,
      );
    } else {
      return ref.newInstance(positionalParams, namedParams);
    }
  }

  Expression _buildInstanceForModule(DependencyConfig dep) {
    final module = dep.moduleConfig!;
    if (!module.isMethod) {
      return refer(
        toCamelCase(module.type.name),
      ).property(module.initializerName);
    }

    return refer(toCamelCase(module.type.name)).newInstanceNamed(
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
    );
  }

  Expression _getDisposeFunctionAssignment(DisposeFunctionConfig disposeFunction) {
    if (disposeFunction.isInstance) {
      return Method((b) => b
        ..requiredParameters.add(Parameter((b) => b.name = 'i'))
        ..body = refer('i').property(disposeFunction.name).call([]).code).closure;
    } else {
      return typeRefer(disposeFunction.importableType!, targetFile);
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
    getAsyncReferName ??= asExtension ? 'getAsync' : 'get.getAsync';
    getReferName ??= 'get';
    final isAsync = isAsyncOrHasAsyncDependency(iDep, _scopeDependencies);
    final expression = refer(isAsync ? getAsyncReferName : getReferName).call([], {
      if (iDep.instanceName != null) 'instanceName': literalString(iDep.instanceName!),
    }, [
      typeRefer(iDep.type, targetFile, false),
    ]);
    return isAsync ? expression.awaited : expression;
  }
}

bool moduleHasOverrides(Iterable<DependencyConfig> deps) {
  return deps.where((d) => d.moduleConfig?.isAbstract == true).any(
        (d) => d.dependencies.isNotEmpty == true,
      );
}
