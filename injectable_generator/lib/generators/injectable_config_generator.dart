import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/external_module_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

import 'package:injectable_generator/utils.dart';

class InjectableConfigGenerator extends GeneratorForAnnotation<InjectableInit> {
  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final generateForDir = annotation
        .read('generateForDir')
        .listValue
        .map((e) => e.toStringValue());

    final usesNullSafety = annotation.read('usesNullSafety').boolValue;
    final isMicroPackage = annotation.read('_isMicroPackage').boolValue;
    final usesConstructorCallback =
        annotation.read('usesConstructorCallback').boolValue;
    final throwOnMissingDependencies =
        annotation.read('throwOnMissingDependencies').boolValue;
    final targetFile = element.source?.uri;
    final preferRelativeImports =
        annotation.read("preferRelativeImports").boolValue;

    final includeMicroPackages =
        annotation.read("includeMicroPackages").boolValue;

    final rootDir = annotation.peek('rootDir')?.stringValue;

    final dirPattern = generateForDir.length > 1
        ? '{${generateForDir.join(',')}}'
        : '${generateForDir.first}';

    final injectableConfigFiles = Glob("$dirPattern/**.injectable.json");

    final jsonData = <Map>[];
    await for (final id in buildStep.findAssets(injectableConfigFiles)) {
      final json = jsonDecode(await buildStep.readAsString(id));
      jsonData.addAll([...json]);
    }

    final deps = <DependencyConfig>[];
    for (final json in jsonData) {
      deps.add(DependencyConfig.fromJson(json));
    }

    final initializerName = annotation.read('initializerName').stringValue;
    final asExtension = annotation.read('asExtension').boolValue;

    final typeResolver =
        ImportableTypeResolverImpl(await buildStep.resolver.libraries.toList());

    final ignoredTypes =
        annotation.read('ignoreUnregisteredTypes').listValue.map(
              (e) => typeResolver.resolveType(e.toTypeValue()!),
            );

    final microPackageModulesBefore = _getMicroPackageModules(
      annotation.peek('externalPackageModulesBefore'),
      typeResolver,
    );

    // remove after deprecation period
    if (microPackageModulesBefore.isEmpty) {
      microPackageModulesBefore.addAll(
        _getMicroPackageModulesMapped(
          annotation.peek('externalPackageModules'),
          typeResolver,
        ),
      );
    }

    final microPackageModulesAfter = _getMicroPackageModules(
      annotation.peek('externalPackageModulesAfter'),
      typeResolver,
    );

    final microPackagesModules =
        microPackageModulesBefore.union(microPackageModulesAfter);
    if (!isMicroPackage && includeMicroPackages) {
      final glob = Glob('**.module.dart', recursive: true);
      final filesStream = glob.list(root: rootDir);

      await for (final match in filesStream) {
        final commentAnnotation = File(match.path).readAsLinesSync().first;
        if (commentAnnotation.contains('@GeneratedMicroModule')) {
          final segments = commentAnnotation.split(';');
          if (segments.length == 3) {
            final externalModule = ExternalModuleConfig(
              ImportableType(
                name: segments[1],
                import: segments[2],
              ),
            );
            if (!microPackagesModules
                .any((e) => externalModule.module == e.module)) {
              microPackageModulesBefore.add(externalModule);
            }
          }
        }
      }
    }

    final ignoreTypesInPackages = annotation
        .read('ignoreUnregisteredTypesInPackages')
        .listValue
        .map((e) => e.toStringValue())
        .where((e) => e != null)
        .cast<String>()
        .toList();

    // we want to ignore unregistered types in microPackages
    // because the micro module should handle them
    for (final pckModule in microPackagesModules) {
      final packageName =
          Uri.parse(pckModule.module.import!).pathSegments.first;
      ignoreTypesInPackages.add(packageName);
    }

    _reportMissingDependencies(
      deps,
      ignoredTypes,
      ignoreTypesInPackages,
      targetFile,
      throwOnMissingDependencies,
    );
    _validateDuplicateDependencies(deps);

    /// don't allow registering of the same dependency with both async and sync factories
    final groupedByType = deps.groupListsBy((d) => (d.type, d.instanceName));
    for (final entry in groupedByType.entries) {
      final first = entry.value.first;
      final isAsync = first.isAsync && !first.preResolve;
      throwIf(
        entry.value.any((e) => (e.isAsync && !e.preResolve) != isAsync),
        'Dependencies of type [${entry.key.$1}] must either all be async or all be sync\n',
      );
    }

    final generator = LibraryGenerator(
      dependencies: List.of(deps),
      targetFile: preferRelativeImports ? targetFile : null,
      initializerName: initializerName,
      asExtension: asExtension,
      microPackageName:
          isMicroPackage ? buildStep.inputId.package.pascalCase : null,
      microPackagesModulesBefore: microPackageModulesBefore,
      microPackagesModulesAfter: microPackageModulesAfter,
      usesConstructorCallback: usesConstructorCallback,
    );

    final generatedLib = generator.generate();
    final emitter = DartEmitter(
      allocator: _HashedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: usesNullSafety,
    );

    final output = DartFormatter(
      languageVersion: DartFormatter.latestShortStyleLanguageVersion,
    ).format(generatedLib.accept(emitter).toString());

    if (isMicroPackage) {
      final outputId = buildStep.inputId.changeExtension('.module.dart');
      return buildStep.writeAsString(
        outputId,
        [
          '//@GeneratedMicroModule;${capitalize(buildStep.inputId.package.pascalCase)}PackageModule;${outputId.uri}',
          defaultFileHeader,
          output,
        ].join('\n'),
      );
    }
    return output;
  }

  Set<ExternalModuleConfig> _getMicroPackageModules(
    ConstantReader? constList,
    ImportableTypeResolverImpl typeResolver,
  ) {
    return constList?.listValue.map(
          (e) {
            final reader = ConstantReader(e);
            final typeValue = reader.read('module').typeValue;
            final scope = reader.peek('scope')?.stringValue;
            throwIf(
              typeValue.element is! ClassElement ||
                  !TypeChecker.fromRuntime(MicroPackageModule)
                      .isSuperOf(typeValue.element!),
              'ExternalPackageModule must be a class that extends MicroPackageModule',
            );
            return ExternalModuleConfig(
                typeResolver.resolveType(typeValue), scope);
          },
        ).toSet() ??
        <ExternalModuleConfig>{};
  }

  Set<ExternalModuleConfig> _getMicroPackageModulesMapped(
    ConstantReader? constList,
    ImportableTypeResolverImpl typeResolver,
  ) {
    return constList?.listValue.map(
          (e) {
            final typeValue = e.toTypeValue()!;
            throwIf(
              typeValue.element is! ClassElement ||
                  !TypeChecker.fromRuntime(MicroPackageModule)
                      .isSuperOf(typeValue.element!),
              'ExternalPackageModule must be a class that extends MicroPackageModule',
            );
            return ExternalModuleConfig(typeResolver.resolveType(typeValue));
          },
        ).toSet() ??
        <ExternalModuleConfig>{};
  }

  void _reportMissingDependencies(
    List<DependencyConfig> deps,
    Iterable<ImportableType> ignoredTypes,
    Iterable<String> ignoredTypesInPackages,
    Uri? targetFile,
    bool throwOnMissingDependencies,
  ) {
    final messages = [];
    for (final dep in deps) {
      for (var iDep in dep.dependencies.where(
          (d) => !d.isFactoryParam && d.instanceName != kEnvironmentsName)) {
        if ((ignoredTypes.contains(iDep.type) ||
            (iDep.type.import == null ||
                ignoredTypesInPackages.any(
                  (type) => iDep.type.import!.startsWith('package:$type'),
                )))) {
          continue;
        }

        final possibleDeps = lookupPossibleDeps(iDep, deps);

        if (possibleDeps.isEmpty) {
          messages.add(
              "[${dep.typeImpl}] depends on unregistered type [${iDep.type}] ${iDep.type.import == null ? '' : 'from ${iDep.type.import}'}");
        } else {
          final availableEnvs = possibleDeps
              .map((e) => e.environments)
              .reduce((a, b) => a + b)
              .toSet();
          if (availableEnvs.isNotEmpty) {
            final missingEnvs =
                dep.environments.toSet().difference(availableEnvs);
            if (missingEnvs.isNotEmpty) {
              messages.add(
                '[${dep.typeImpl}] ${dep.environments.toSet()} depends on Type [${iDep.type}] ${iDep.type.import == null ? '' : 'from ${iDep.type.import}'} \n which is not available under environment keys $missingEnvs',
              );
            }
          }
        }
      }
    }

    if (messages.isNotEmpty) {
      messages.add(
          '\nDid you forget to annotate the above class(s) or their implementation with @injectable? \nor add the right environment keys?');
      throwIf(throwOnMissingDependencies, messages.join('\n'));
      printBoxed(messages.join('\n'),
          header: "Missing dependencies in ${targetFile?.path}\n");
    }
  }

  void _validateDuplicateDependencies(List<DependencyConfig> deps) {
    final validatedDeps = <DependencyConfig>[];
    for (var dep in deps) {
      var registered = validatedDeps.where(
        (elm) =>
            elm.type == dep.type &&
            elm.instanceName == dep.instanceName &&
            elm.scope == dep.scope,
      );

      if (registered.isEmpty) {
        validatedDeps.add(dep);
      } else {
        Set<String> registeredEnvironments = registered
            .fold(<String>{}, (prev, elm) => prev..addAll(elm.environments));

        if (registeredEnvironments.isEmpty ||
            dep.environments
                .any((env) => registeredEnvironments.contains(env))) {
          throwBoxed(
            '${dep.typeImpl} [${dep.type}] envs: ${dep.environments}  scope: ${dep.scope} \nis registered more than once under the same environment or in the same scope',
          );
        }
      }
    }
  }
}

/// The reason to use this allocator is to avoid changing in the alias of the imports
/// With this allocator, we can hash the url of the import and use it as an alias
/// This will make sure that the alias is consistent across multiple runs avoiding conflicts
class _HashedAllocator implements Allocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};

  String? _url;
  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol;
    _url = reference.url;
    if (_url == null || _doNotPrefix.contains(_url)) {
      return symbol!;
    }

    return '_i${_imports.putIfAbsent(_url!, _hashedUrl)}.$symbol';
  }

  int _hashedUrl() => _url.hashCode / 1000000 ~/ 1;

  @override
  Iterable<Directive> get imports => _imports.keys.map(
        (u) => Directive.import(u, as: '_i${_imports[u]}'),
      );
}
