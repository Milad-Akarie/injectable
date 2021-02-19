import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:injectable_generator/generator/generator_utils.dart';
import 'package:injectable_generator/utils.dart';
import 'package:meta/meta.dart';

import '../dependency_config.dart';
import '../injectable_types.dart';

const injectableImport = 'package:injectable/injectable.dart';
const getItImport = 'package:get_it/get_it.dart';

const getItRefer = Reference('GetIt', getItImport);
const gh = Reference('gh');

TypeReference typeRefer(
  String symbol, {
  String url,
  bool nullable = false,
}) =>
    TypeReference(
      (b) => b
        ..symbol = symbol
        ..url = url
        ..isNullable = nullable,
    );

String generateLibrary({
  List<DependencyConfig> allDeps,
  Uri targetFile,
  String initializerName,
  bool asExtension = false,
}) {
  // sort dependencies alphabetically
  allDeps.sort((a, b) => a.type.name.compareTo(b.type.name));

  // sort dependencies by their register order
  final Set<DependencyConfig> sorted = {};
  GeneratorUtils.sortByDependents(allDeps.toSet(), sorted);

  // if true use an awaited initializer
  final hasPreResolvedDeps = GeneratorUtils.hasPreResolvedDeps(sorted);

  // eager singleton instances are registered at the end
  final eagerDeps = sorted
      .where(
        (d) => d.injectableType == InjectableType.singleton,
      )
      .toSet();

  final lazyDeps = sorted.difference(eagerDeps);
  // all environment keys used
  final environments = sorted.fold(
    <String>{},
    (prev, elm) => prev..addAll(elm.environments),
  );

  // all register modules
  final modules = sorted.where((d) => d.isFromModule).map((d) => d.module).toSet();
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
            ..types.add(getItRefer))
          : getItRefer
      ..name = initializerName
      ..modifier = hasPreResolvedDeps ? MethodModifier.async : null
      ..requiredParameters.addAll([
        if (!asExtension)
          Parameter(
            (b) => b
              ..name = 'get'
              ..type = getItRefer,
          )
      ])
      ..optionalParameters.addAll([
        Parameter((b) => b
          ..named = true
          ..name = 'environment'
          ..type = typeRefer(
            'String',
            nullable: true,
          )),
        Parameter((b) => b
          ..named = true
          ..name = 'environmentFilter'
          ..type = typeRefer(
            'EnvironmentFilter',
            url: injectableImport,
            nullable: true,
          ))
      ])
      ..body = Block(
        (b) => b.statements.addAll([
          refer('GetItHelper', injectableImport)
              .newInstance(
                [
                  getInstanceRefer,
                  refer('environment'),
                  refer('environmentFilter'),
                ],
              )
              .assignFinal('gh')
              .statement,
          ...modules.map((module) =>
              refer('_\$${module.name}').call([getInstanceRefer]).assignFinal(toCamelCase(module.name)).statement),
          ...lazyDeps.map((dep) => buildLazyRegisterFun(dep, targetFile)),
          ...eagerDeps.map((dep) => buildSingletonRegisterFun(dep, targetFile)),
          getInstanceRefer.returned.statement,
        ]),
      ),
  );

  final library = Library(
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

          asExtension
              ? Extension(
                  (b) => b
                    ..docs.addAll([
                      if (asExtension) ...ignoreForFileComments,
                      '/// an extension to register the provided dependencies inside of [GetIt]',
                    ])
                    ..name = 'GetItInjectableX'
                    ..on = getItRefer
                    ..methods.add(intiMethod),
                )
              : intiMethod,
          // build modules
          ...modules.map(
            (module) => _buildModule(
              module,
              sorted.where((e) => e.module == module),
              targetFile,
            ),
          )
        ],
      ),
  );

  final emitter = DartEmitter(Allocator.simplePrefixing(), true, false);
  return DartFormatter().format(library.accept(emitter).toString());
}

Class _buildModule(ImportableType module, Iterable<DependencyConfig> deps, [Uri targetFile]) {
  final abstractDeps = deps.where((d) => d.isAbstract);
  return Class((clazz) {
    clazz
      ..name = '_\$${module.name}'
      ..extend = module.refer(targetFile);
    // check weather we should have a getIt field inside of our module
    if (abstractDeps.any((d) => d.dependencies?.isNotEmpty == true)) {
      clazz.fields.add(Field(
        (b) => b
          ..name = '_getIt'
          ..type = getItRefer
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
          ..name = dep.initializerName
          ..returns = dep.typeImpl.refer(targetFile)
          ..type = dep.isModuleMethod ? null : MethodType.getter
          ..body = _buildInstance(dep, targetFile, getReferName: '_getIt').code,
      ),
    ));
    return clazz;
  });
}

Code buildLazyRegisterFun(
  DependencyConfig dep, [
  Uri targetFile,
]) {
  var funcReferName;
  Map<String, Reference> factoryParams = {};
  if (dep.injectableType == InjectableType.factory) {
    final hasFactoryParams = dep.dependencies.any((d) => d.isFactoryParam);
    if (hasFactoryParams) {
      funcReferName = dep.isAsync ? 'factoryParamAsync' : 'factoryParam';
      factoryParams.addAll(_resolveFactoryParams(dep, targetFile));
    } else {
      funcReferName = dep.isAsync ? 'factoryAsync' : 'factory';
    }
  } else if (dep.injectableType == InjectableType.lazySingleton) {
    funcReferName = dep.isAsync ? 'lazySingletonAsync' : 'lazySingleton';
  }
  throwIf(funcReferName == null, 'Injectable type is not supported');

  final registerExpression = gh.property(funcReferName).call([
    Method(
      (b) => b
        ..lambda = true
        ..requiredParameters.addAll(
          factoryParams.keys.map(
            (name) => Parameter((b) => b.name = name),
          ),
        )
        ..body =
            dep.isFromModule ? _buildInstanceForModule(dep, targetFile).code : _buildInstance(dep, targetFile).code,
    ).closure
  ], {
    if (dep.instanceName != null) 'instanceName': literalString(dep.instanceName),
    if (dep.environments?.isNotEmpty == true)
      'registerFor': literalSet(
        dep.environments.map((e) => refer('_$e')),
      ),
    if (dep.preResolve == true) 'preResolve': literalBool(true)
  }, [
    dep.type.refer(targetFile),
    ...factoryParams.values.map((p) => p.type)
  ]);
  return dep.preResolve ? registerExpression.awaited.statement : registerExpression.statement;
}

Map<String, Reference> _resolveFactoryParams(DependencyConfig dep, [Uri targetFile]) {
  final params = <String, Reference>{};
  dep.dependencies.where((d) => d.isFactoryParam).forEach((d) {
    params[d.paramName] = d.type.refer(targetFile);
  });
  if (params.length < 2) {
    params['_'] = refer('dynamic');
  }
  return params;
}

Code buildSingletonRegisterFun(
  DependencyConfig dep, [
  Uri targetFile,
]) {
  var funcReferName;
  var asFactory = true;
  if (dep.isAsync) {
    funcReferName = 'singletonAsync';
  } else if (dep.dependsOn?.isNotEmpty == true) {
    funcReferName = 'singletonWithDependencies';
  } else {
    asFactory = false;
    funcReferName = 'singleton';
  }

  final instanceBuilder = dep.isFromModule ? _buildInstanceForModule(dep, targetFile) : _buildInstance(dep, targetFile);
  final registerExpression = gh.property(funcReferName).call([
    asFactory
        ? Method((b) => b
          ..lambda = true
          ..body = instanceBuilder.code).closure
        : instanceBuilder
  ], {
    if (dep.instanceName != null) 'instanceName': literalString(dep.instanceName),
    if (dep.dependsOn?.isNotEmpty == true)
      'dependsOn': literalList(
        dep.dependsOn.map(
          (e) => e.refer(targetFile),
        ),
      ),
    if (dep.environments?.isNotEmpty == true)
      'registerFor': literalSet(
        dep.environments.map((e) => refer('_$e')),
      ),
    if (dep.signalsReady != null) 'signalsReady': literalBool(dep.signalsReady),
    if (dep.preResolve == true) 'preResolve': literalBool(true)
  }, [
    dep.type.refer(targetFile)
  ]);

  return dep.preResolve ? registerExpression.awaited.statement : registerExpression.statement;
}

Expression _buildInstance(
  DependencyConfig dep,
  Uri targetFile, {
  String getReferName = 'get',
}) {
  final positionalParams = dep.positionalDeps.map(
    (iDep) => _buildParamAssignment(iDep, targetFile, name: getReferName),
  );

  final namedParams = Map.fromEntries(
    dep.namedDeps.map(
      (iDep) => MapEntry(
        iDep.paramName,
        _buildParamAssignment(iDep, targetFile, name: getReferName),
      ),
    ),
  );

  final ref = dep.typeImpl.refer(targetFile);
  if (dep.constructorName?.isNotEmpty == true) {
    return ref
        .newInstanceNamed(
          dep.constructorName,
          positionalParams,
          namedParams,
        )
        .expression;
  } else {
    return ref.newInstance(positionalParams, namedParams).expression;
  }
}

Expression _buildInstanceForModule(DependencyConfig dep, Uri targetFile) {
  if (!dep.isModuleMethod) {
    return refer(
      toCamelCase(dep.module.name),
    ).property(dep.initializerName).expression;
  }

  return refer(toCamelCase(dep.module.name))
      .newInstanceNamed(
        dep.initializerName,
        dep.positionalDeps.map(
          (iDep) => _buildParamAssignment(iDep, targetFile, name: 'get'),
        ),
        Map.fromEntries(
          dep.namedDeps.map(
            (iDep) => MapEntry(
              iDep.paramName,
              _buildParamAssignment(iDep, targetFile, name: 'get'),
            ),
          ),
        ),
      )
      .expression;
}

Expression _buildParamAssignment(
  InjectedDependency iDep,
  Uri targetFile, {
  @required String name,
}) {
  if (iDep.isFactoryParam) {
    return refer(iDep.paramName);
  }
  return refer(name).call([], {
    if (iDep.instanceName != null) 'instanceName': literalString(iDep.instanceName),
  }, [
    iDep.type.refer(targetFile),
  ]);
}
