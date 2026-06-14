import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/external_module_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
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

/// A library that generates code for registering dependencies in GetIt based on a list of [DependencyConfig]s.
/// It supports generating code for different scopes, handling asynchronous dependencies, and integrating with external modules.
mixin SharedGeneratorCode {
  /// A list of dependencies to be registered, wrapped in a [DependencyList] for additional functionality.
  DependencyList get dependencies;

  /// The target file URI for resolving imports, which can be used to generate relative import paths.
  Uri? get targetFile;

  /// A flag indicating whether to generate extension methods for registration or standalone functions.
  bool get asExtension;

  /// Builds an instance expression for the given dependency.
  ///
  /// Uses either positional or named parameters based on the dependency's
  /// injected dependencies. Handles const constructors if [dep.canBeConst] is true.
  Expression _buildInstance(
    DependencyConfig dep, {
    String? getAsyncMethodName,
    String? getMethodName,
  }) {
    final positionalParams = dep.positionalDependencies.map(
      (iDep) => _buildParamAssignment(
        iDep,
        getAsyncReferName: getAsyncMethodName,
        getReferName: getMethodName,
      ),
    );

    final namedParams = Map.fromEntries(
      dep.namedDependencies.map(
        (iDep) => MapEntry(
          iDep.paramName,
          _buildParamAssignment(
            iDep,
            getAsyncReferName: getAsyncMethodName,
            getReferName: getMethodName,
          ),
        ),
      ),
    );

    final ref = typeRefer(dep.typeImpl, targetFile);
    if (dep.constructorName.isNotEmpty == true) {
      final constructor = dep.canBeConst
          ? ref.constInstanceNamed
          : ref.newInstanceNamed;
      return constructor(dep.constructorName, positionalParams, namedParams);
    } else {
      final constructor = dep.canBeConst ? ref.constInstance : ref.newInstance;
      return constructor(positionalParams, namedParams);
    }
  }

  /// Builds the parameter assignment expression for an injected dependency.
  ///
  /// Resolves to either a factory parameter reference or a GetIt async/sync
  /// retrieval expression depending on the dependency configuration.
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
    final isAsync = dependencies.isAsyncOrHasAsyncDependency(iDep);
    final expression = refer(isAsync ? getAsyncReferName : getReferName).call(
      [],
      {
        if (iDep.instanceName != null)
          'instanceName': literalString(iDep.instanceName!),
      },
      [typeRefer(iDep.type, targetFile, false)],
    );
    return isAsync ? expression.awaited : expression;
  }
}

/// Generates the library code containing extension methods, accessor methods,
/// initialization functions, and module implementations for a set of dependencies.
class LibraryGenerator with SharedGeneratorCode {
  @override
  late DependencyList dependencies;
  @override
  final Uri? targetFile;
  @override
  final bool asExtension;

  /// The name of the initializer method to generate for the root scope, which will be called to register dependencies in GetIt.
  final bool usesConstructorCallback;

  /// The name of the initializer method to generate for the root scope, which will be called to register dependencies in GetIt.
  final String initializerName;

  /// The name of the micro-package module being generated, if applicable. If null, this library is not a micro-package module.
  final String? microPackageName;

  /// The sets of external modules that should be initialized before and after registering the dependencies in this library,
  ///  used for micro-package module chaining. The `microPackagesModulesBefore` set contains modules that should be initialized
  /// before the dependencies in this library, while the `microPackagesModulesAfter` set contains modules that should be initialized after. These sets are used to generate the appropriate initialization code in the generated library.
  final Set<ExternalModuleConfig> microPackagesModulesBefore,
      microPackagesModulesAfter;

  /// Creates an instance of [LibraryGenerator] with the provided configuration parameters, including the dependencies
  /// to register, the initializer name, and micro-package module chaining information.
  final bool generateAccessors;

  /// Allows multiple registrations of the same type within this library, which can be useful for certain testing
  /// scenarios or when using named instances. When true, it enables the `enableRegisteringMultipleInstancesOfOneType` flag on GetIt.
  final bool allowMultipleRegistrations;

  /// Default constructor
  LibraryGenerator({
    required List<DependencyConfig> dependencies,
    required this.initializerName,
    this.targetFile,
    this.asExtension = false,
    this.generateAccessors = false,
    this.microPackageName,
    this.microPackagesModulesBefore = const {},
    this.microPackagesModulesAfter = const {},
    this.usesConstructorCallback = false,
    this.allowMultipleRegistrations = false,
  }) : dependencies = DependencyList(dependencies: dependencies);

  /// Generates the main library containing scopes, initializers, accessors, and modules.
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

    if (isMicroPackage && scopedDeps.length > 1) {
      throw 'Scopes are not supported in micro package modules!';
    }

    // make sure root scope is always generated even if empty
    if (!scopedDeps.containsKey(null)) {
      scopedDeps = {null: const [], ...scopedDeps};
    }
    final allScopeKeys = {
      ...scopedDeps.keys,
      ...scopedBeforeExternalModules.keys,
      ...scopedAfterExternalModules.keys,
    };
    final extMethods = <Method>[];
    for (final scope in allScopeKeys) {
      final scopeDeps = scopedDeps[scope];
      final isRootScope = scope == null;
      extMethods.add(
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
          allowMultipleRegistrations: allowMultipleRegistrations,
        ).generate(),
      );
    }

    generateAccessorMethods(extMethods);

    return Library(
      (b) => b
        ..comments.addAll([
          'ignore_for_file: type=lint',
          'coverage:ignore-file',
        ])
        ..body.addAll([
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
                  ..methods.addAll(extMethods),
              )
            else
              ...extMethods,
          ],

          if (isMicroPackage)
            Class(
              (b) => b
                ..name = '${capitalize(microPackageName!)}PackageModule'
                ..extend = refer('MicroPackageModule', _injectableImport)
                ..methods.add(extMethods.first),
            ),

          // build modules
          ...modules.map(
            (module) => _buildModule(
              module,
              dependencies.where((e) => e.moduleConfig == module),
            ),
          ),
        ]),
    );
  }

  /// Generates type-safe accessor methods for each dependency that is not from a module.
  /// These accessors can be called directly on the GetIt instance.
  void generateAccessorMethods(List<Method> extMethods) {
    if (!generateAccessors) return;
    final usedTypes = <ImportableType>{};
    for (final dep in dependencies) {
      if (dep.isFromModule || !usedTypes.add(dep.typeImpl)) {
        continue;
      }
      final passesArgs =
          dep.dependencies.any((d) => d.isFactoryParam) ||
          dep.instanceName != null;
      final isAsyncOrHasAsyncDep =
          dep.isAsync ||
          dep.dependencies.any(dependencies.isAsyncOrHasAsyncDependency);
      final returns = isAsyncOrHasAsyncDep
          ? TypeReference(
              (b) => b
                ..symbol = 'Future'
                ..types.add(typeRefer(dep.typeImpl, targetFile)),
            )
          : typeRefer(dep.typeImpl, targetFile);
      extMethods.add(
        Method(
          (b) {
            b
              ..name = toCamelCase(dep.typeImpl.name)
              ..returns = returns
              ..type = passesArgs ? null : MethodType.getter
              ..lambda = true;
            // add parameters for factory params
            if (dep.instanceName != null) {
              b.optionalParameters.add(
                Parameter(
                  (pb) => pb
                    ..named = true
                    ..name = 'instanceName'
                    ..type = nullableRefer('String', nullable: true),
                ),
              );
            }
            for (final iDep in dep.dependencies.where(
              (d) => d.isFactoryParam,
            )) {
              b.optionalParameters.add(
                Parameter(
                  (pb) => pb
                    ..required = iDep.isRequired && !iDep.type.isNullable
                    ..named = true
                    ..name = iDep.paramName
                    ..type = typeRefer(iDep.type, targetFile),
                ),
              );
            }

            int paramIndex = 0;
            b.body =
                refer(
                      isAsyncOrHasAsyncDep ? 'getAsync' : 'get',
                    )
                    .call(
                      [],
                      {
                        if (dep.instanceName != null)
                          'instanceName': refer('instanceName'),
                        for (final iDep in dep.dependencies.where(
                          (d) => d.isFactoryParam,
                        ))
                          'param${++paramIndex}': refer(iDep.paramName),
                      },
                      [typeRefer(dep.typeImpl, targetFile)],
                    )
                    .code;
          },
        ),
      );
    }
  }

  /// Generates a private class that overrides abstract module methods to provide
  /// concrete implementations using GetIt dependencies.
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

/// Generates the initialization method for a specific scope (or the root scope)
/// to register all dependencies within that scope into GetIt.
class InitMethodGenerator with SharedGeneratorCode {
  @override
  late DependencyList dependencies;
  @override
  final Uri? targetFile;
  @override
  final bool asExtension;

  /// All dependencies across scopes, used for determining module overrides and async dependencies.
  final DependencyList allDependencies;

  /// The name of the initializer method to generate (e.g., `init
  final String initializerName;

  /// The name of the scope for which this initializer is being generated, or null for the root scope.
  final String? scopeName;

  /// Indicates whether this initializer is being generated for a micro-package module, which affects the return type and method signature.
  final bool isMicroPackage;

  /// Indicates whether to wrap instance creation with a constructor callback, allowing for custom logic to be applied to all instances after construction.
  final bool usesConstructorCallback;

  /// Allows multiple registrations of the same type within this scope, which can be useful for certain testing scenarios or when using named instances. When true, it enables the `enableRegisteringMultipleInstancesOfOneType` flag on GetIt.
  final bool allowMultipleRegistrations;

  /// The set of external modules that should be initialized before registering the dependencies in this scope, used for micro-package module chaining.
  final Set<ExternalModuleConfig> microPackagesModulesBefore,
      microPackagesModulesAfter;

  /// Default constructor
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
    this.allowMultipleRegistrations = false,
  }) : assert(microPackagesModulesBefore.isEmpty || scopeName == null),
       dependencies = DependencyList(dependencies: scopeDependencies);

  /// Generates the initialization method AST node.
  ///
  /// Handles async modifiers, micro-package module chaining, and scope-specific
  /// registration logic.
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

    final ghBuilder = refer('GetItHelper', _injectableImport).newInstance([
      getInstanceRefer,
      refer('environment'),
      refer('environmentFilter'),
    ]);

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
                ..type = nullableRefer('String', nullable: true),
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
                  ..type = nullableRefer('T Function<T>(T)', nullable: true),
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
              if (allowMultipleRegistrations && !isMicroPackage)
                getInstanceRefer
                    .property('enableRegisteringMultipleInstancesOfOneType')
                    .call([])
                    .statement,
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

  /// Builds the code expression for registering a lazy or factory dependency.
  ///
  /// Determines the appropriate registration function (e.g., `factory`, `factoryParam`,
  /// `lazySingleton`) based on the dependency's injectable type, async state, and caching.
  Code buildLazyRegisterFun(DependencyConfig dep) {
    String? funcReferName;
    Map<String, Reference> factoryParams = {};
    final hasAsyncDep = dependencies.hasAsyncDependency(dep);
    final isOrHasAsyncDep = dep.isAsync || hasAsyncDep;

    if (dep.injectableType == InjectableType.factory) {
      final hasFactoryParams = dep.dependencies.any((d) => d.isFactoryParam);
      if (hasFactoryParams) {
        funcReferName = switch ((isOrHasAsyncDep, dep.cache == true)) {
          (true, true) => 'factoryCachedParamAsync',
          (false, true) => 'factoryCachedParam',
          (false, false) => 'factoryParam',
          (true, false) => 'factoryParamAsync',
        };

        factoryParams.addAll(_resolveFactoryParams(dep));
      } else {
        funcReferName = switch ((isOrHasAsyncDep, dep.cache == true)) {
          (true, true) => 'factoryCachedAsync',
          (false, true) => 'factoryCached',
          (false, false) => 'factory',
          (true, false) => 'factoryAsync',
        };
      }
    } else if (dep.injectableType == InjectableType.lazySingleton) {
      funcReferName = isOrHasAsyncDep ? 'lazySingletonAsync' : 'lazySingleton';
    }
    if (funcReferName == null) {
      throw 'Injectable type is not supported';
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
            ..requiredParameters.addAll(
              factoryParams.keys.map((name) => Parameter((b) => b.name = name)),
            )
            ..body = instanceBuilderCode,
        ).closure,
      ],
      {
        if (dep.instanceName != null)
          'instanceName': literalString(dep.instanceName!),
        if (dep.environments.isNotEmpty == true)
          'registerFor': literalSet(dep.environments.map((e) => refer('_$e'))),
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

  /// Wraps the instance builder code with constructor callbacks and post-construction
  /// logic (e.g., `@postConstruct`) if configured for the dependency.
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

  /// Resolves the factory parameter names and their corresponding type references
  /// for a dependency that requires factory parameters.
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

  /// Builds the code expression for registering a singleton dependency.
  ///
  /// Selects between regular, async, or dependency-aware singleton registration
  /// functions based on the dependency's configuration.
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
            dep.dependsOn.map((e) => typeRefer(e, targetFile)),
          ),
        if (dep.environments.isNotEmpty)
          'registerFor': literalSet(dep.environments.map((e) => refer('_$e'))),
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

  /// Builds the instance expression for a dependency that is provided by a module.
  ///
  /// Differentiates between module properties (getters) and module methods (functions).
  Expression _buildInstanceForModule(DependencyConfig dep) {
    final module = dep.moduleConfig!;
    if (!module.isMethod) {
      return refer(
        toCamelCase(module.type.name),
      ).property(module.initializerName);
    }

    return refer(toCamelCase(module.type.name)).newInstanceNamed(
      module.initializerName,
      dep.positionalDependencies.map((iDep) => _buildParamAssignment(iDep)),
      Map.fromEntries(
        dep.namedDependencies.map(
          (iDep) => MapEntry(iDep.paramName, _buildParamAssignment(iDep)),
        ),
      ),
    );
  }

  /// Generates the disposal function expression for a dependency.
  ///
  /// Handles both instance method disposals and standalone disposal function references.
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

/// Checks if any dependency within a module requires GetIt overrides,
/// indicating that the module needs a `_getIt` instance field.
bool moduleHasOverrides(Iterable<DependencyConfig> deps) {
  return deps
      .where((d) => d.moduleConfig?.isAbstract == true)
      .any((d) => d.dependencies.isNotEmpty == true);
}
