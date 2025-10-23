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
  DependencyList get dependencies;

  Uri? get targetFile;

  bool get asExtension;

  Expression _buildInstance(
    DependencyConfig dep, {
    String? getAsyncMethodName,
    String? getMethodName,
    Map<String, String> typeToParamName = const {},
  }) {

    final positionalParams = dep.positionalDependencies.map(
      (iDep) => _buildParamAssignment(
        iDep,
        getAsyncReferName: getAsyncMethodName,
        getReferName: getMethodName,
        typeToParamName: typeToParamName,
      ),
    ).toList();

    final namedParams = Map.fromEntries(
      dep.namedDependencies.map(
        (iDep) => MapEntry(
          iDep.paramName,
          _buildParamAssignment(
            iDep,
            getAsyncReferName: getAsyncMethodName,
            getReferName: getMethodName,
            typeToParamName: typeToParamName,
          ),
        ),
      ),
    );

    final ref = typeRefer(dep.typeImpl, targetFile);
    if (dep.constructorName?.isNotEmpty == true) {
      final constructor = dep.canBeConst
          ? ref.constInstanceNamed
          : ref.newInstanceNamed;
      return constructor(
        dep.constructorName!,
        positionalParams,
        namedParams,
      );
    } else {
      final constructor = dep.canBeConst ? ref.constInstance : ref.newInstance;
      return constructor(positionalParams, namedParams);
    }
  }

  Expression _buildParamAssignment(
    InjectedDependency iDep, {
    String? getAsyncReferName,
    String? getReferName,
    required Map<String, String> typeToParamName,
  }) {
    if (iDep.isFactoryParam) {
      return refer(iDep.paramName);
    }
    getAsyncReferName ??= asExtension ? 'getAsync' : 'gh.getAsync';
    getReferName ??= 'gh';
    final isAsync = dependencies.isAsyncOrHasAsyncDependency(iDep);

    final depConfig = lookupDependency(iDep, dependencies.toList());

    final namedParams = <String, Expression>{
      if (iDep.instanceName != null)
        'instanceName': literalString(iDep.instanceName!),
    };

    if (depConfig != null && dependencies.hasFactoryParams(depConfig)) {
      final childParams = _collectFactoryParams(depConfig, <String>{});

      if (childParams.isNotEmpty) {
        for (int i = 0; i < childParams.length; i++) {
          final childParam = childParams[i];
          final typeIdentity = childParam.type.type.identity;
          final parentParamName = typeToParamName[typeIdentity];

          if (parentParamName != null) {
            namedParams['param${i + 1}'] = refer(parentParamName);
          }
        }
      }
    }

    final expression = refer(isAsync ? getAsyncReferName : getReferName).call(
      [],
      namedParams,
      [
        typeRefer(iDep.type, targetFile, false),
      ],
    );
    return isAsync ? expression.awaited : expression;
  }

  List<_FactoryParam> _collectFactoryParams(DependencyConfig dep, Set<String> visited) {
    final depId = '${dep.type.name}_${dep.instanceName ?? ''}';
    if (visited.contains(depId)) {
      return [];
    }
    visited.add(depId);
    List<_FactoryParam> params = [];
    for (final d in dep.dependencies.where((d) => d.isFactoryParam)) {
      params.add(_FactoryParam(
        name: d.paramName,
        type: d,
        typeRef: typeRefer(d.type, targetFile),
      ));
    }

    for (final childDep in dep.dependencies.where((d) => !d.isFactoryParam)) {
      final childConfig = lookupDependency(childDep, dependencies.toList());
      if (childConfig != null && dependencies.hasFactoryParams(childConfig)) {
        params.addAll(_collectFactoryParams(childConfig, visited));
      }
    }
    return params;
  }
}

class LibraryGenerator with SharedGeneratorCode {
  @override
  late DependencyList dependencies;
  @override
  final Uri? targetFile;
  @override
  final bool asExtension;
  final bool usesConstructorCallback;
  final String initializerName;
  final String? microPackageName;
  final Set<ExternalModuleConfig> microPackagesModulesBefore,
      microPackagesModulesAfter;

  LibraryGenerator({
    required List<DependencyConfig> dependencies,
    required this.initializerName,
    this.targetFile,
    this.asExtension = false,
    this.microPackageName,
    this.microPackagesModulesBefore = const {},
    this.microPackagesModulesAfter = const {},
    this.usesConstructorCallback = false,
  }) : dependencies = DependencyList(dependencies: dependencies);

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

    var scopedDeps = groupBy<DependencyConfig, String?>(
      dependencies,
      (d) => d.scope,
    );
    final scopedBeforeExternalModules = groupBy<ExternalModuleConfig, String?>(
      microPackagesModulesBefore,
      (d) => d.scope,
    );
    final scopedAfterExternalModules = groupBy<ExternalModuleConfig, String?>(
      microPackagesModulesAfter,
      (d) => d.scope,
    );

    final isMicroPackage = microPackageName != null;

    throwIf(
      isMicroPackage && scopedDeps.length > 1,
      'Scopes are not supported in micro package modules!',
    );

    // make sure root scope is always generated even if empty
    if (!scopedDeps.containsKey(null)) {
      scopedDeps = {null: const [], ...scopedDeps};
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
          initializerName: isRootScope
              ? initializerName
              : 'init${capitalize(scope)}Scope',
          asExtension: asExtension,
          scopeName: scope,
          isMicroPackage: isMicroPackage,
          microPackagesModulesBefore:
              scopedBeforeExternalModules[scope]?.toSet() ?? const {},
          microPackagesModulesAfter:
              scopedAfterExternalModules[scope]?.toSet() ?? const {},
          usesConstructorCallback: usesConstructorCallback,
        ).generate(),
      );
    }

    return Library(
      (b) => b
        ..comments.addAll([
          'ignore_for_file: type=lint',
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
            ),
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
        clazz.fields.add(
          Field(
            (b) => b
              ..name = '_getIt'
              ..type = _getItRefer
              ..modifier = FieldModifier.final$,
          ),
        );
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
      clazz.methods.addAll(
        abstractDeps.map(
          (dep) => Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = dep.moduleConfig!.initializerName
              ..returns = typeRefer(dep.typeImpl, targetFile)
              ..type = dep.moduleConfig!.isMethod ? null : MethodType.getter
              ..body = _buildInstance(
                dep,
                getAsyncMethodName: '_getIt.getAsync',
                getMethodName: '_getIt',
              ).code,
          ),
        ),
      );
    });
  }
}

class InitMethodGenerator with SharedGeneratorCode {
  @override
  late DependencyList dependencies;
  @override
  final Uri? targetFile;
  @override
  final bool asExtension;

  final DependencyList allDependencies;
  final String initializerName;
  final String? scopeName;
  final bool isMicroPackage;
  final bool usesConstructorCallback;
  final Set<ExternalModuleConfig> microPackagesModulesBefore,
      microPackagesModulesAfter;

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
    this.usesConstructorCallback = false,
  }) : assert(microPackagesModulesBefore.isEmpty || scopeName == null),
       dependencies = DependencyList(dependencies: scopeDependencies);

  Method generate() {
    // if true use an awaited initializer
    final useAsyncModifier =
        microPackagesModulesBefore.isNotEmpty ||
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
      for (final pckModule in microPackagesModulesBefore.map((e) => e.module))
        refer(
              pckModule.name,
              pckModule.import,
            )
            .newInstance(const [])
            .property('init')
            .call([_ghLocalRefer])
            .awaited
            .statement,
      ...modules.map(
        (module) => declareFinal(toCamelCase(module.type.name))
            .assign(
              refer('_\$${module.type.name}').call([
                if (moduleHasOverrides(
                  allDependencies.where((e) => e.moduleConfig == module),
                ))
                  getInstanceRefer,
              ]),
            )
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
        refer(
              pckModule.name,
              pckModule.import,
            )
            .newInstance(const [])
            .property('init')
            .call([_ghLocalRefer])
            .awaited
            .statement,
    ];

    final Reference returnRefer;
    if (isMicroPackage) {
      returnRefer = TypeReference(
        (b) => b
          ..symbol = 'FutureOr'
          ..url = 'dart:async'
          ..types.add(refer('void')),
      );
    } else {
      returnRefer = useAsyncModifier
          ? TypeReference(
              (b) => b
                ..symbol = 'Future'
                ..types.add(_getItRefer),
            )
          : _getItRefer;
    }

    final ghBuilder = refer('GetItHelper', _injectableImport).newInstance(
      [
        getInstanceRefer,
        refer('environment'),
        refer('environmentFilter'),
      ],
    );

    return Method(
      (b) => b
        ..docs.add(
          '\n// initializes the registration of ${scopeName ?? 'main'}-scope dependencies inside of GetIt',
        )
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
            ),
        ])
        ..optionalParameters.addAll([
          if (scopeName == null && !isMicroPackage) ...[
            Parameter(
              (b) => b
                ..named = true
                ..name = 'environment'
                ..type = nullableRefer(
                  'String',
                  nullable: true,
                ),
            ),
            Parameter(
              (b) => b
                ..named = true
                ..name = 'environmentFilter'
                ..type = nullableRefer(
                  'EnvironmentFilter',
                  url: _injectableImport,
                  nullable: true,
                ),
            ),
            if (usesConstructorCallback)
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'constructorCallback'
                  ..type = nullableRefer(
                    'T Function<T>(T)',
                    nullable: true,
                  ),
              ),
          ] else if (!isMicroPackage)
            Parameter(
              (b) => b
                ..named = true
                ..name = 'dispose'
                ..type = nullableRefer(
                  'ScopeDisposeFunc',
                  url: _getItImport,
                  nullable: true,
                ),
            ),
        ])
        ..body = Block(
          (b) => b.statements.addAll([
            if (scopeName != null)
              _ghRefer
                  .newInstance([getInstanceRefer])
                  .property('initScope${useAsyncModifier ? 'Async' : ''}')
                  .call(
                    [literalString(scopeName!)],
                    {
                      'dispose': refer('dispose'),
                      'init': Method(
                        (b) => b
                          ..modifier = useAsyncModifier
                              ? MethodModifier.async
                              : null
                          ..requiredParameters.add(
                            Parameter(
                              (b) => b
                                ..name = 'gh'
                                ..type = refer(
                                  'GetItHelper',
                                  _injectableImport,
                                ),
                            ),
                          )
                          ..body = Block(
                            (b) => b.statements.addAll(ghStatements),
                          ),
                      ).closure,
                    },
                  )
                  .returned
                  .statement
            else ...[
              if (!isMicroPackage)
                if (dependencies.isNotEmpty ||
                    microPackagesModulesAfter.isNotEmpty ||
                    microPackagesModulesBefore.isNotEmpty)
                  declareFinal('gh').assign(ghBuilder).statement
                else
                  ghBuilder.statement,
              if (usesConstructorCallback)
                declareFinal('ccb')
                    .assign(
                      refer(
                        'constructorCallback',
                      ).ifNullThen(CodeExpression(Code('<T>(_) => _'))),
                    )
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
    Map<String, String> typeToParamName = {};
    final hasAsyncDep = dependencies.hasAsyncDependency(dep);
    final isOrHasAsyncDep = dep.isAsync || hasAsyncDep;

    if (dep.injectableType == InjectableType.factory) {
      final hasDirectFactoryParams = dep.dependencies.any((d) => d.isFactoryParam);
      final hasTransitiveFactoryParams = dependencies.hasFactoryParams(dep);
      final hasFactoryParams = hasDirectFactoryParams || hasTransitiveFactoryParams;

      if (hasFactoryParams) {
        funcReferName = isOrHasAsyncDep ? 'factoryParamAsync' : 'factoryParam';
        final resolved = _resolveFactoryParams(dep);
        factoryParams = resolved.params;
        typeToParamName = resolved.typeToParamName;
      } else {
        funcReferName = isOrHasAsyncDep ? 'factoryAsync' : 'factory';
      }
    } else if (dep.injectableType == InjectableType.lazySingleton) {
      funcReferName = isOrHasAsyncDep ? 'lazySingletonAsync' : 'lazySingleton';
    }
    throwIf(funcReferName == null, 'Injectable type is not supported');

    final instanceBuilder = dep.isFromModule
        ? _buildInstanceForModule(dep, typeToParamName: typeToParamName)
        : _buildInstance(dep, typeToParamName: typeToParamName);
    final instanceBuilderCode = _buildInstanceBuilderCode(instanceBuilder, dep);
    final registerExpression = _ghLocalRefer.property(funcReferName!).call(
      [
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
        ).closure,
      ],
      {
        if (dep.instanceName != null)
          'instanceName': literalString(dep.instanceName!),
        if (dep.environments.isNotEmpty == true)
          'registerFor': literalSet(
            dep.environments.map((e) => refer('_$e')),
          ),
        if (dep.preResolve == true) 'preResolve': literalBool(true),
        if (dep.disposeFunction != null)
          'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!),
      },
      [
        typeRefer(dep.type, targetFile),
        ...factoryParams.values.map((p) => p.type),
      ],
    );
    return dep.preResolve
        ? registerExpression.awaited.statement
        : registerExpression.statement;
  }

  Code _buildInstanceBuilderCode(
    Expression instanceBuilder,
    DependencyConfig dep,
  ) {
    if (usesConstructorCallback) {
      instanceBuilder = refer('ccb').call([instanceBuilder]);
    }
    var instanceBuilderCode = instanceBuilder.code;
    if (dep.postConstruct != null) {
      if (dep.postConstructReturnsSelf) {
        instanceBuilderCode = instanceBuilder
            .property(dep.postConstruct!)
            .call(const [])
            .code;
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
                          ..requiredParameters.add(
                            Parameter((b) => b..name = '_'),
                          ),
                      ).closure,
                    ])
                    .returned
                    .statement,
              ]),
          );
        } else {
          instanceBuilderCode = instanceBuilder
              .cascade(dep.postConstruct!)
              .call(const [])
              .code;
        }
      }
    }
    return instanceBuilderCode;
  }

  _ResolvedFactoryParams _resolveFactoryParams(DependencyConfig dep) {
    final directParams = <_FactoryParam>[];
    for (final d in dep.dependencies.where((d) => d.isFactoryParam)) {
      directParams.add(_FactoryParam(
        name: d.paramName,
        type: d,
        typeRef: typeRefer(d.type, targetFile),
      ));
    }

    final allParams = _collectFactoryParams(dep, {});
    final uniqueTypeRefs = <String, Reference>{};
    for (final param in allParams) {
      final typeIdentity = param.type.type.identity;
      if (!uniqueTypeRefs.containsKey(typeIdentity)) {
        uniqueTypeRefs[typeIdentity] = param.typeRef;
      }
    }

    final params = <String, Reference>{};
    final typeToParamName = <String, String>{};

    int paramIndex = 0;
    final directParamTypes = <String>{};
    for (final param in directParams) {
      paramIndex++;
      params[param.name] = param.typeRef;
      directParamTypes.add(param.type.type.identity);
      typeToParamName[param.type.type.identity] = param.name;
    }

    for (final entry in uniqueTypeRefs.entries) {
      final typeIdentity = entry.key;
      if (directParamTypes.contains(typeIdentity)) {
        continue;
      }

      paramIndex++;
      final paramName = 'param$paramIndex';
      params[paramName] = entry.value;
      typeToParamName[typeIdentity] = paramName;
    }

    if (params.length < 2) {
      params['_'] = refer('dynamic');
    }
    return _ResolvedFactoryParams(
      params: params,
      typeToParamName: typeToParamName,
    );
  }

  Code buildSingletonRegisterFun(DependencyConfig dep) {
    String funcReferName;
    final hasAsyncDep = dependencies.hasAsyncDependency(dep);
    if (dep.isAsync || hasAsyncDep) {
      funcReferName = 'singletonAsync';
    } else if (dep.dependsOn.isNotEmpty) {
      funcReferName = 'singletonWithDependencies';
    } else {
      funcReferName = 'singleton';
    }

    final instanceBuilder = dep.isFromModule
        ? _buildInstanceForModule(dep)
        : _buildInstance(dep);
    final instanceBuilderCode = _buildInstanceBuilderCode(instanceBuilder, dep);
    final registerExpression = _ghLocalRefer.property(funcReferName).call(
      [
        Method(
          (b) => b
            ..lambda = instanceBuilderCode is! Block
            ..modifier = hasAsyncDep ? MethodModifier.async : null
            ..body = instanceBuilderCode,
        ).closure,
      ],
      {
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
          'dispose': _getDisposeFunctionAssignment(dep.disposeFunction!),
      },
      [typeRefer(dep.type, targetFile)],
    );

    return dep.preResolve
        ? registerExpression.awaited.statement
        : registerExpression.statement;
  }

  Expression _buildInstanceForModule(
    DependencyConfig dep, {
    Map<String, String> typeToParamName = const {},
  }) {

    final module = dep.moduleConfig!;
    if (!module.isMethod) {
      return refer(
        toCamelCase(module.type.name),
      ).property(module.initializerName);
    }

    return refer(toCamelCase(module.type.name)).newInstanceNamed(
      module.initializerName,
      dep.positionalDependencies.map(
        (iDep) => _buildParamAssignment(iDep, typeToParamName: typeToParamName),
      ),
      Map.fromEntries(
        dep.namedDependencies.map(
          (iDep) => MapEntry(
            iDep.paramName,
            _buildParamAssignment(iDep, typeToParamName: typeToParamName),
          ),
        ),
      ),
    );
  }

  Expression _getDisposeFunctionAssignment(
    DisposeFunctionConfig disposeFunction,
  ) {
    if (disposeFunction.isInstance) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b.name = 'i'))
          ..body = refer('i').property(disposeFunction.name).call([]).code,
      ).closure;
    } else {
      return typeRefer(disposeFunction.importableType!, targetFile);
    }
  }
}

bool moduleHasOverrides(Iterable<DependencyConfig> deps) {
  return deps
      .where((d) => d.moduleConfig?.isAbstract == true)
      .any(
        (d) => d.dependencies.isNotEmpty == true,
      );
}

class _FactoryParam {
  final String name;
  final InjectedDependency type;
  final Reference typeRef;

  _FactoryParam({
    required this.name,
    required this.type,
    required this.typeRef,
  });
}

class _ResolvedFactoryParams {
  final Map<String, Reference> params;
  final Map<String, String> typeToParamName;

  _ResolvedFactoryParams({
    required this.params,
    required this.typeToParamName,
  });
}
