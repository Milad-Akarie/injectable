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

Library generateLibrary({
  required List<DependencyConfig> dependencies,
  required String initializerName,
  Uri? targetFile,
  bool asExtension = false,
}) {
  final sorted = sortDependencies(dependencies);

  // if true use an awaited initializer
  final hasPreResolvedDeps = hasPreResolvedDependencies(sorted);

  // eager singleton instances are registered at the end
  final eagerDeps = <DependencyConfig>{};
  final lazyDeps = <DependencyConfig>{};
  // all environment keys used
  final environments = <String>{};
  // all register modules
  final modules = <ModuleConfig>{};
  sorted.forEach((dep) {
    environments.addAll(dep.environments);

    if (dep.injectableType == InjectableType.singleton) {
      eagerDeps.add(dep);
    } else {
      lazyDeps.add(dep);
    }
    if (dep.moduleConfig != null) {
      modules.add(dep.moduleConfig!);
    }
  });

  final ignoreForFileComments = [
    '// ignore_for_file: unnecessary_lambdas',
    '// ignore_for_file: lines_longer_than_80_chars'
  ];
  final getInstanceRefer = refer(asExtension ? 'this' : 'get');
  final intiMethod = Method(
    (b) => b
      ..docs.addAll([
        if (!asExtension) ...ignoreForFileComments,
        '/// initializes the registration of provided dependencies inside of [GetIt]'
      ])
      ..returns = hasPreResolvedDeps
          ? TypeReference((b) => b
            ..symbol = 'Future'
            ..types.add(_getItRefer))
          : _getItRefer
      ..name = initializerName
      ..modifier = hasPreResolvedDeps ? MethodModifier.async : null
      ..requiredParameters.addAll([
        if (!asExtension)
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
                  sorted.where((e) => e.moduleConfig == module),
                ))
                  getInstanceRefer
              ])
              .assignFinal(toCamelCase(module.type.name))
              .statement),
          ...lazyDeps
              .map((dep) => buildLazyRegisterFun(dep, sorted, targetFile)),
          ...eagerDeps
              .map((dep) => buildSingletonRegisterFun(dep, sorted, targetFile)),
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

          if (asExtension)
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
          if (!asExtension) intiMethod,
          // build modules
          ...modules.map(
            (module) => _buildModule(
              module,
              sorted.where((e) => e.moduleConfig == module),
              sorted,
              targetFile,
            ),
          )
        ],
      ),
  );
}

Class _buildModule(ModuleConfig module, Iterable<DependencyConfig> deps,
    Set<DependencyConfig> allDeps,
    [Uri? targetFile]) {
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
          ..body =
              _buildInstance(dep, allDeps, targetFile, getReferName: '_getIt')
                  .code,
      ),
    ));
  });
}

Code buildLazyRegisterFun(
  DependencyConfig dep,
  Set<DependencyConfig> allDeps, [
  Uri? targetFile,
]) {
  var funcReferName;
  Map<String, Reference> factoryParams = {};
  final hasAsyncDep = hasAsyncDependency(dep, allDeps);
  final isOrHasAsyncDep = dep.isAsync || hasAsyncDep;

  if (dep.injectableType == InjectableType.factory) {
    final hasFactoryParams = dep.dependencies.any((d) => d.isFactoryParam);
    if (hasFactoryParams) {
      funcReferName = isOrHasAsyncDep ? 'factoryParamAsync' : 'factoryParam';
      factoryParams.addAll(_resolveFactoryParams(dep, targetFile));
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
            ? _buildInstanceForModule(dep, allDeps, targetFile).code
            : _buildInstance(dep, allDeps, targetFile).code,
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
      'dispose': _getDisposeFunctionAssignment(
        dep.disposeFunction!,
        targetFile,
      )
  }, [
    typeRefer(dep.type, targetFile),
    ...factoryParams.values.map((p) => p.type)
  ]);
  return dep.preResolve
      ? registerExpression.awaited.statement
      : registerExpression.statement;
}

Map<String, Reference> _resolveFactoryParams(DependencyConfig dep,
    [Uri? targetFile]) {
  final params = <String, Reference>{};
  dep.dependencies.where((d) => d.isFactoryParam).forEach((d) {
    params[d.paramName] = typeRefer(d.type, targetFile);
  });
  if (params.length < 2) {
    params['_'] = refer('dynamic');
  }
  return params;
}

Code buildSingletonRegisterFun(
  DependencyConfig dep,
  Set<DependencyConfig> allDeps, [
  Uri? targetFile,
]) {
  var funcReferName;
  var asFactory = true;
  final hasAsyncDep = hasAsyncDependency(dep, allDeps);
  if (dep.isAsync || hasAsyncDep) {
    funcReferName = 'singletonAsync';
  } else if (dep.dependsOn.isNotEmpty) {
    funcReferName = 'singletonWithDependencies';
  } else {
    asFactory = false;
    funcReferName = 'singleton';
  }

  final instanceBuilder = dep.isFromModule
      ? _buildInstanceForModule(dep, allDeps, targetFile)
      : _buildInstance(dep, allDeps, targetFile);
  final registerExpression = _ghRefer.property(funcReferName).call([
    asFactory
        ? Method((b) => b
          ..lambda = true
          ..modifier = hasAsyncDep ? MethodModifier.async : null
          ..body = instanceBuilder.code).closure
        : instanceBuilder
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
      'dispose': _getDisposeFunctionAssignment(
        dep.disposeFunction!,
        targetFile,
      )
  }, [
    typeRefer(dep.type, targetFile)
  ]);

  return dep.preResolve
      ? registerExpression.awaited.statement
      : registerExpression.statement;
}

Expression _buildInstance(
  DependencyConfig dep,
  Set<DependencyConfig> allDeps,
  Uri? targetFile, {
  String getReferName = 'get',
}) {
  final positionalParams = dep.positionalDependencies.map(
    (iDep) =>
        _buildParamAssignment(iDep, allDeps, targetFile, name: getReferName),
  );

  final namedParams = Map.fromEntries(
    dep.namedDependencies.map(
      (iDep) => MapEntry(
        iDep.paramName,
        _buildParamAssignment(iDep, allDeps, targetFile, name: getReferName),
      ),
    ),
  );

  final ref = typeRefer(dep.typeImpl, targetFile);
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

Expression _buildInstanceForModule(
    DependencyConfig dep, Set<DependencyConfig> allDeps, Uri? targetFile) {
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
          (iDep) =>
              _buildParamAssignment(iDep, allDeps, targetFile, name: 'get'),
        ),
        Map.fromEntries(
          dep.namedDependencies.map(
            (iDep) => MapEntry(
              iDep.paramName,
              _buildParamAssignment(iDep, allDeps, targetFile, name: 'get'),
            ),
          ),
        ),
      )
      .expression;
}

Expression _getDisposeFunctionAssignment(DisposeFunctionConfig disposeFunction,
    [Uri? targetFile]) {
  if (disposeFunction.isInstance) {
    return Method((b) => b
      ..requiredParameters.add(Parameter((b) => b.name = 'i'))
      ..body = refer('i').property(disposeFunction.name).call([]).code).closure;
  } else {
    return typeRefer(disposeFunction.importableType!, targetFile);
  }
}

Expression _buildParamAssignment(
  InjectedDependency iDep,
  Set<DependencyConfig> allDeps,
  Uri? targetFile, {
  required String name,
}) {
  if (iDep.isFactoryParam) {
    return refer(iDep.paramName);
  }
  final isAsync = isAsyncOrHasAsyncDependency(iDep, allDeps);
  final expression = refer(isAsync ? '$name.getAsync' : name).call([], {
    if (iDep.instanceName != null)
      'instanceName': literalString(iDep.instanceName!),
  }, [
    typeRefer(iDep.type, targetFile, false),
  ]);
  return isAsync ? expression.awaited : expression;
}

bool moduleHasOverrides(Iterable<DependencyConfig> deps) {
  return deps.where((d) => d.moduleConfig?.isAbstract == true).any(
        (d) => d.dependencies.isNotEmpty == true,
      );
}
