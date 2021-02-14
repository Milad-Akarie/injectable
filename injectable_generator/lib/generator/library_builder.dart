import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../dependency_config.dart';
import '../injectable_types.dart';

const injectableImport = 'package:injectable/injectable.dart';
const getItImport = 'package:get_it/get_it.dart';

const getItRefer = Reference('GetIt', getItImport);
const gh = Reference('gh');
const get = Reference('get');

String generateLibrary({
  List<DependencyConfig> allDeps,
  Uri targetFile,
  String initializerName,
}) {
  // sort dependencies alphabetically
  allDeps.sort((a, b) => a.type.name.compareTo(b.type.name));

  // sort dependencies by their register order
  final Set<DependencyConfig> sorted = {};
  _sortByDependents(allDeps.toSet(), sorted);

  // if true use an awaited initializer
  final hasAsync = _hasAsync(sorted);

  // eager singleton instances are registered at the end
  final eagerDeps = sorted.where((d) => d.injectableType == InjectableType.singleton).toSet();

  final lazyDeps = sorted.difference(eagerDeps);
  // final gh = GetItHelper(this, environment, environmentFilter);
  // all environment keys used
  final environments = sorted.fold(<String>{}, (prev, elm) => prev..addAll(elm.environments));
  final library = Library(
    (b) => b
      ..body.addAll(
        [
          ...environments.map((env) => Field(
                (b) => b
                  ..name = '_$env'
                  ..type = refer('String')
                  ..assignment = literal(env).code
                  ..modifier = FieldModifier.constant,
              )),
          Extension(
            (b) => b
              ..name = 'GetItInjectableX'
              ..on = getItRefer
              ..methods.add(Method(
                (b) => b
                  ..returns = hasAsync
                      ? TypeReference((b) => b
                        ..symbol = 'Future'
                        ..types.add(getItRefer))
                      : getItRefer
                  ..name = initializerName
                  ..modifier = hasAsync ? MethodModifier.async : null
                  ..optionalParameters.addAll([
                    Parameter((b) => b
                      ..named = true
                      ..name = 'environment'
                      ..type = refer('String')),
                    Parameter((b) => b
                      ..named = true
                      ..name = 'environmentFilter'
                      ..type = refer('EnvironmentFilter', injectableImport))
                  ])
                  ..body = Block(
                    (b) => b.statements.addAll([
                      refer('GetItHelper', injectableImport)
                          .newInstance(
                            [
                              refer('this'),
                              refer('environment'),
                              refer('environmentFilter'),
                            ],
                          )
                          .assignFinal('gh')
                          .statement,
                      ...lazyDeps.map((d) => _factory(d, targetFile)),
                      refer('this').returned.statement,
                    ]),
                  ),
              )),
          )
        ],
      ),
  );

  // gh.factory<Service>(() => resolvedService, registerFor: {_prod});
  final emitter = DartEmitter(Allocator.simplePrefixing(), true, true);
  print(DartFormatter().format(library.accept(emitter).toString()));
  return DartFormatter().format(library.accept(emitter).toString());
}

Code _factory(DependencyConfig dep, [Uri targetFile]) {
  return gh.property('factory').call([
    Method(
      (b) => b
        ..lambda = true
        ..body = _buildInstance(dep, targetFile),
    ).closure
  ], {}, [
    dep.type.refer(targetFile)
  ]).statement;
}

Code _buildInstance(DependencyConfig dep, Uri targetFile) {
  return dep.typeImpl
      .refer(targetFile)
      .newInstance(
          dep.positionalDeps.map(
            (iDep) => get.call([], {}, [iDep.type.refer(targetFile)]),
          ),
          Map.fromEntries(
            dep.namedDeps.map(
              (iDep) => MapEntry(
                iDep.name,
                get.call([], {}, [iDep.type.refer(targetFile)]),
              ),
            ),
          ))
      .code;
}

void _sortByDependents(Set<DependencyConfig> unSorted, Set<DependencyConfig> sorted) {
  for (var dep in unSorted) {
    if (dep.dependencies.every(
      (iDep) =>
          iDep.isFactoryParam ||
          sorted.map((d) => d.type).contains(iDep.type) ||
          !unSorted.map((d) => d.type).contains(iDep.type),
    )) {
      sorted.add(dep);
    }
  }
  if (unSorted.isNotEmpty) {
    _sortByDependents(unSorted.difference(sorted), sorted);
  }
}

bool _hasAsync(Set<DependencyConfig> deps) {
  return deps.any((d) => d.isAsync && d.preResolve);
}
