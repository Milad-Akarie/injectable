import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/external_module_config.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:injectable_generator/utils.dart';
import 'package:collection/collection.dart';
import '../injectable_types.dart';

const _injectableImport = 'package:injectable/injectable.dart';
const _getItImport = 'package:get_it/get_it.dart';
const _getItRefer = Reference('GetIt', _getItImport);
const _ghRefer = Reference('GetItHelper', _injectableImport);
const _ghLocalRefer = Reference('gh');

mixin SharedGeneratorCode {
  Set<DependencyConfig> get dependencies;

  Uri? get targetFile;

  bool get asExtension;

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

  Expression _buildParamAssignment(
    InjectedDependency iDep, {
    String? getAsyncReferName,
    String? getReferName,
  }) {
    if (iDep.isFactoryParam) {
      return refer(iDep.paramName);
    }
    getAsyncReferName ??= asExtension ? 'getAsync' : 'gh.getAsync';
    getReferName ??= 'gh';
    final isAsync = isAsyncOrHasAsyncDependency(iDep, dependencies);
    final expression =
        refer(isAsync ? getAsyncReferName : getReferName).call([], {
      if (iDep.instanceName != null)
        'instanceName': literalString(iDep.instanceName!),
    }, [
      typeRefer(iDep.type, targetFile, false),
    ]);
    return isAsync ? expression.awaited : expression;
  }
}

class LibraryGenerator with SharedGeneratorCode {
  @override
  late Set<DependencyConfig> dependencies;
  @override
  final Uri? targetFile;
  @override
  final bool asExtension;
  final String initializerName;
  final String? microPackageName;
  final Set<ExternalModuleConfig> microPackagesModulesBefore,
      microPackagesModulesAfter;
  final bool createNewGetItInstance;

  LibraryGenerator({
    required this.dependencies,
    required this.initializerName,
    this.targetFile,
    this.asExtension = false,
    this.microPackageName,
    this.microPackagesModulesBefore = const {},
    this.microPackagesModulesAfter = const {},
    this.createNewGetItInstance = false,
  });

  Library generate() {
    // all environment keys used
    final environments = <String>{};
    // all register modules
    final modules = <ModuleConfig>{};
    for (final dep in dependencies) {
      environments.addAll(dep.environments);
      if (dep.moduleConfig != null) {
        modules.add(dep.moduleConfig!);
      }
    }

    final scopedDeps =
        groupBy<DependencyConfig, String?>(dependencies, (d) => d.scope);
    final scopedBeforeExternalModules = groupBy<ExternalModuleConfig, String?>(
        microPackagesModulesBefore, (d) => d.scope);
    final scopedAfterExternalModules = groupBy<ExternalModuleConfig, String?>(
        microPackagesModulesAfter, (d) => d.scope);

    final isMicroPackage = microPackageName != null;

    throwIf(
      isMicroPackage && scopedDeps.length > 1,
      'Scopes are not supported in micro package modules!',
    );

    if (scopedDeps.isEmpty) {
      scopedDeps[null] = [];
    }
    final allScopeKeys = {
      ...scopedDeps.keys,
      ...scopedBeforeExternalModules.keys,
      ...scopedAfterExternalModules.keys,
    };
    final initMethods = <Method>[];
    for (final scope in allScopeKeys) {
      final scopeDeps = scopedDeps[scope];
      final isRootScope = scope == null;
      initMethods.add(
        InitMethodGenerator(
          scopeDependencies: scopeDeps ?? [],
          targetFile: targetFile,
          allDependencies: dependencies,
          initializerName:
              isRootScope ? initializerName : 'init${capitalize(scope)}Scope',
          asExtension: asExtension,
          scopeName: scope,
          isMicroPackage: isMicroPackage,
          microPackagesModulesBefore:
              scopedBeforeExternalModules[scope]?.toSet() ?? const {},
          microPackagesModulesAfter:
              scopedAfterExternalModules[scope]?.toSet() ?? const {},
          createNewGetItInstance: createNewGetItInstance,
          microPackageName: microPackageName,
        ).generate(),
      );
    }

    return Library(
      (b) => b
        ..comments.addAll([
          'ignore_for_file: unnecessary_lambdas',
          'ignore_for_file: lines_longer_than_80_chars',
          'coverage:ignore-file',
        ])
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
            if (!isMicroPackage) ...[
              if (asExtension)
                Extension(
                  (b) => b
                    ..name = 'GetItInjectableX'
                    ..on = _getItRefer
                    ..methods.addAll(initMethods),
                )
              else
                ...initMethods,
            ],

            if (isMicroPackage && createNewGetItInstance)
              Field(
                (b) => b
                  ..name = '${toCamelCase(microPackageName!)}GetIt'
                  ..type = refer('GetItHelper', _injectableImport)
                  ..late = true
                  ..modifier = FieldModifier.var$,
              ),

            if (isMicroPackage)
              Class(
                (b) => b
                  ..name = '${capitalize(microPackageName!)}PackageModule'
                  ..extend = refer(
                    'MicroPackageModule',
                    _injectableImport,
                  )
                  ..methods.add(initMethods.first),
              ),

            // build modules
            ...modules.map(
              (module) => _buildModule(
                module,
                dependencies.where((e) => e.moduleConfig == module),
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
            ..body = _buildInstance(dep,
                    getAsyncMethodName: '_getIt.getAsync',
                    getMethodName: '_getIt')
                .code,
        ),
      ));
    });
  }
}

class InitMethodGenerator with SharedGeneratorCode {
  @override
  late Set<DependencyConfig> dependencies;
  @override
  final Uri? targetFile;
  @override
  final bool asExtension;

  final Set<DependencyConfig> allDependencies;
  final String initializerName;
  final String? scopeName;
  final bool isMicroPackage;
  final Set<ExternalModuleConfig> microPackagesModulesBefore,
      microPackagesModulesAfter;
  final bool createNewGetItInstance;
  final String? microPackageName;

  InitMethodGenerator({
    required List<DependencyConfig> scopeDependencies,
    required this.allDependencies,
    required this.initializerName,
    this.targetFile,
    this.asExtension = false,
    this.scopeName,
    this.isMicroPackage = false,
    this.microPackagesModulesBefore = const {},
    this.microPackagesModulesAfter = const {},
    this.createNewGetItInstance = false,
    this.microPackageName,
  }) {
    assert(microPackagesModulesBefore.isEmpty || scopeName == null);
    dependencies = sortDependencies(scopeDependencies);
  }

  Method generate() {
    // if true use an awaited initializer
    final useAsyncModifier = microPackagesModulesBefore.isNotEmpty ||
        microPackagesModulesAfter.isNotEmpty ||
        hasPreResolvedDependencies(dependencies);

    // all register modules
    final modules = <ModuleConfig>{};
    for (var dep in dependencies) {
      if (dep.moduleConfig != null) {
        modules.add(dep.moduleConfig!);
      }
    }

    final getInstanceRefer = refer(asExtension ? 'this' : 'getIt');

    final ghStatements = [
      if (createNewGetItInstance && isMicroPackage)
        Code('${toCamelCase(microPackageName!)}GetIt = gh;'),
      for (final pckModule in microPackagesModulesBefore.map((e) => e.module))
        refer(pckModule.name, pckModule.import)
            .newInstance(const [])
            .property('init')
            .call([_ghLocalRefer])
            .awaited
            .statement,
      ...modules.map(
        (module) => declareFinal(toCamelCase(module.type.name))
            .assign(refer('_\$${module.type.name}').call([
              if (moduleHasOverrides(
                allDependencies.where((e) => e.moduleConfig == module),
              ))
                getInstanceRefer
            ]))
            .statement,
      ),
      ...dependencies.map((dep) {
        if (dep.injectableType == InjectableType.singleton) {
          return buildSingletonRegisterFun(dep);
        } else {
          return buildLazyRegisterFun(dep);
        }
      }),
      for (final pckModule in microPackagesModulesAfter.map((e) => e.module))
        refer(pckModule.name, pckModule.import)
            .newInstance(const [])
            .property('init')
            .call([_ghLocalRefer])
            .awaited
            .statement,
    ];

    final Reference returnRefer;
    if (isMicroPackage) {
      returnRefer = TypeReference((b) => b
        ..symbol = 'FutureOr'
        ..url = 'dart:async'
        ..types.add(refer('void')));
    } else {
      returnRefer = useAsyncModifier
          ? TypeReference((b) => b
            ..symbol = 'Future'
            ..types.add(_getItRefer))
          : _getItRefer;
    }

    return Method(
      (b) => b
        ..docs.addAll([
          if (!asExtension && scopeName == null && !isMicroPackage) ...[
            '\n// ignore_for_file: unnecessary_lambdas',
            '// ignore_for_file: lines_longer_than_80_chars'
          ],
          '// initializes the registration of ${scopeName ?? 'main'}-scope dependencies inside of GetIt'
        ])
        ..modifier = useAsyncModifier ? MethodModifier.async : null
        ..returns = returnRefer
        ..name = initializerName
        ..annotations.addAll([if (isMicroPackage) refer('override')])
        ..requiredParameters.addAll([
          if (!asExtension && !isMicroPackage)
            Parameter(
              (b) => b
                ..name = 'getIt'
                ..type = _getItRefer,
            ),
          if (isMicroPackage)
            Parameter(
              (b) => b
                ..name = 'gh'
                ..type = _ghRefer,
            )
        ])
        ..optionalParameters.addAll([
          if (scopeName == null && !isMicroPackage) ...[
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
          ] else if (!isMicroPackage)
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
              _ghRefer
                  .newInstance([getInstanceRefer])
                  .property('initScope${useAsyncModifier ? 'Async' : ''}')
                  .call([
                    literalString(scopeName!)
                  ], {
                    'dispose': refer('dispose'),
                    'init': Method((b) => b
                      ..modifier =
                          useAsyncModifier ? MethodModifier.async : null
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
              if (!isMicroPackage)
                declareFinal('gh')
                    .assign(refer('GetItHelper', _injectableImport).newInstance(
                      [
                        getInstanceRefer,
                        refer('environment'),
                        refer('environmentFilter'),
                      ],
                    ))
                    .statement,
              ...ghStatements,
              if (!isMicroPackage) getInstanceRefer.returned.statement,
            ],
          ]),
        ),
    );
  }

  Code buildLazyRegisterFun(DependencyConfig dep) {
    String? funcReferName;
    Map<String, Reference> factoryParams = {};
    final hasAsyncDep = hasAsyncDependency(dep, dependencies);
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

    final instanceBuilder =
        dep.isFromModule ? _buildInstanceForModule(dep) : _buildInstance(dep);
    final instanceBuilderCode = _buildInstanceBuilderCode(instanceBuilder, dep);
    final registerExpression = _ghLocalRefer.property(funcReferName!).call([
      Method(
        (b) => b
          ..lambda = instanceBuilderCode is! Block
          ..modifier = hasAsyncDep ? MethodModifier.async : null
          ..requiredParameters.addAll(
            factoryParams.keys.map(
              (name) => Parameter((b) => b.name = name),
            ),
          )
          ..body = instanceBuilderCode,
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
      typeRefer(dep.type, targetFile),
      ...factoryParams.values.map((p) => p.type)
    ]);
    return dep.preResolve
        ? registerExpression.awaited.statement
        : registerExpression.statement;
  }

  Code _buildInstanceBuilderCode(
      Expression instanceBuilder, DependencyConfig dep) {
    var instanceBuilderCode = instanceBuilder.code;
    if (dep.postConstruct != null) {
      if (dep.postConstructReturnsSelf) {
        instanceBuilderCode =
            instanceBuilder.property(dep.postConstruct!).call(const []).code;
      } else {
        if (dep.isAsync) {
          instanceBuilderCode = Block(
            (b) => b
              ..statements.addAll([
                declareFinal('i').assign(instanceBuilder).statement,
                refer('i')
                    .property(dep.postConstruct!)
                    .call(const [])
                    .property('then')
                    .call([
                      Method(
                        (b) => b
                          ..lambda = true
                          ..body = refer('i').code
                          ..requiredParameters
                              .add(Parameter((b) => b..name = '_')),
                      ).closure
                    ])
                    .returned
                    .statement,
              ]),
          );
        } else {
          instanceBuilderCode =
              instanceBuilder.cascade(dep.postConstruct!).call(const []).code;
        }
      }
    }
    return instanceBuilderCode;
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
    String funcReferName;
    var asFactory = true;
    final hasAsyncDep = hasAsyncDependency(dep, dependencies);
    if (dep.isAsync || hasAsyncDep) {
      funcReferName = 'singletonAsync';
    } else if (dep.dependsOn.isNotEmpty) {
      funcReferName = 'singletonWithDependencies';
    } else {
      asFactory = false;
      funcReferName = 'singleton';
    }

    final instanceBuilder =
        dep.isFromModule ? _buildInstanceForModule(dep) : _buildInstance(dep);
    final instanceBuilderCode = _buildInstanceBuilderCode(instanceBuilder, dep);
    final registerExpression = _ghLocalRefer.property(funcReferName).call([
      asFactory
          ? Method((b) => b
            ..lambda = instanceBuilderCode is! Block
            ..modifier = hasAsyncDep ? MethodModifier.async : null
            ..body = instanceBuilderCode).closure
          : CodeExpression(instanceBuilderCode)
    ], {
      if (dep.instanceName != null)
        'instanceName': literalString(dep.instanceName!),
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
      if (dep.signalsReady != null)
        'signalsReady': literalBool(dep.signalsReady!),
      if (dep.preResolve == true) 'preResolve': literalBool(true),
      if (dep.disposeFunction != null)
        'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!)
    }, [
      typeRefer(dep.type, targetFile)
    ]);

    return dep.preResolve
        ? registerExpression.awaited.statement
        : registerExpression.statement;
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

  Expression _getDisposeFunctionAssignment(
      DisposeFunctionConfig disposeFunction) {
    if (disposeFunction.isInstance) {
      return Method((b) => b
            ..requiredParameters.add(Parameter((b) => b.name = 'i'))
            ..body = refer('i').property(disposeFunction.name).call([]).code)
          .closure;
    } else {
      return typeRefer(disposeFunction.importableType!, targetFile);
    }
  }
}

bool moduleHasOverrides(Iterable<DependencyConfig> deps) {
  return deps.where((d) => d.moduleConfig?.isAbstract == true).any(
        (d) => d.dependencies.isNotEmpty == true,
      );
}
