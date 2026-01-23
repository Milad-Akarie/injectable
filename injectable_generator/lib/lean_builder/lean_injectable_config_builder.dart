import 'dart:convert';
import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable_generator/code_builder/allocator.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/lean_builder/resolvers/lean_importable_type_resolver.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/external_module_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';
import 'package:lean_builder/type.dart';

import 'package:injectable_generator/utils.dart';
import 'package:recase/recase.dart';

import '../resolver_utils.dart';
import 'build_utils.dart';

const _configFilesDirectory = '.dart_tool/lean_build/generated';

const _moduleChecker = TypeChecker.typeNamed(
  MicroPackageModule,
  inPackage: 'injectable',
);

@LeanGenerator(
  {'.config.dart', '.module.dart'},
  key: 'InjectableConfigGenerator',
  registerTypes: {InjectableInit},
)
class InjectableConfigGenerator
    extends GeneratorForAnnotatedFunction<InjectableInit> {
  @override
  dynamic generateForFunction(
    BuildStep buildStep,
    FunctionElement element,
    ElementAnnotation anno,
  ) async {
    final annotation = anno.constant as ConstObject;

    final generateForDir = annotation
        .getList('generateForDir')!
        .literalValue
        .cast<String>();

    final usesNullSafety = annotation.getBool('usesNullSafety')!.value;
    final isMicroPackage = annotation.getBool('_isMicroPackage')!.value;
    final usesConstructorCallback = annotation
        .getBool('usesConstructorCallback')!
        .value;
    final throwOnMissingDependencies = annotation
        .getBool('throwOnMissingDependencies')!
        .value;
    final targetFile = element.library.src.uri;
    final preferRelativeImports = annotation
        .getBool("preferRelativeImports")!
        .value;
    final generateForEnvironments =
        annotation
            .getSet('generateForEnvironments')
            ?.value
            .whereType<ConstObject>()
            .map((e) => e.getString('name')?.value) ??
        {};

    final includeMicroPackages = annotation
        .getBool("includeMicroPackages")!
        .value;

    final generateAccessors = annotation.getBool("generateAccessors")!.value;

    final allowMultipleRegistrations =
        annotation.getBool('allowMultipleRegistrations')!.value;

    final rootDir = annotation.getString('rootDir')?.value;

    final jsonData = <Map>[];

    final assets = buildStep.findAssets(
      PathMatcher.regex(r".injectable.ln.json$", dotAll: false),
      subDir: _configFilesDirectory,
    );

    for (final asset in assets) {
      // the location anchor is the path to the root package
      final locationAnchor =
          '$_configFilesDirectory/${buildStep.resolver.fileResolver.rootPackage}/';
      final location = asset.uri.path.split(locationAnchor).lastOrNull ?? '';
      if (generateForDir.any((dir) => location.startsWith(dir))) {
        final json = jsonDecode(asset.readAsStringSync());
        jsonData.addAll([...json]);
      }
    }

    final deps = <DependencyConfig>[];
    for (final json in jsonData) {
      deps.add(DependencyConfig.fromJson(json));
    }

    final initializerName = annotation.getString('initializerName')!.value;
    final asExtension = annotation.getBool('asExtension')!.value;

    final typeResolver = LeanTypeResolverImpl(buildStep.resolver);

    final ignoredTypes =
        annotation
            .getList('ignoreUnregisteredTypes')
            ?.value
            .whereType<ConstType>()
            .map((e) => typeResolver.resolveType(e.value)) ??
        [];

    final microPackageModulesBefore = _getMicroPackageModules(
      annotation.getList('externalPackageModulesBefore'),
      typeResolver,
    );

    // remove after deprecation period
    if (microPackageModulesBefore.isEmpty) {
      microPackageModulesBefore.addAll(
        _getMicroPackageModulesMapped(
          annotation.getList('externalPackageModules'),
          typeResolver,
        ),
      );
    }

    final microPackageModulesAfter = _getMicroPackageModules(
      annotation.getList('externalPackageModulesAfter'),
      typeResolver,
    );

    final microPackagesModules = microPackageModulesBefore.union(
      microPackageModulesAfter,
    );
    if (!isMicroPackage && includeMicroPackages) {
      final glob = Glob('**.module.dart', recursive: true);
      final filesStream = glob.list(root: rootDir);

      await for (final match in filesStream) {
        final commentAnnotation = File(match.path).readAsLinesSync().first;
        if (commentAnnotation.contains('@GeneratedMicroModule')) {
          final segments = commentAnnotation.split(';');
          if (segments.length == 3) {
            final externalModule = ExternalModuleConfig(
              ImportableType(name: segments[1], import: segments[2]),
            );
            if (!microPackagesModules.any(
              (e) => externalModule.module == e.module,
            )) {
              microPackageModulesBefore.add(externalModule);
            }
          }
        }
      }
    }

    final ignoreTypesInPackages =
        annotation
            .getList('ignoreUnregisteredTypesInPackages')
            ?.value
            .whereType<ConstString>()
            .map((e) => e.value)
            .cast<String>()
            .toList() ??
        [];

    // we want to ignore unregistered types in microPackages
    // because the micro module should handle them
    for (final pckModule in microPackagesModules) {
      final packageName = Uri.parse(
        pckModule.module.import!,
      ).pathSegments.first;
      ignoreTypesInPackages.add(packageName);
    }

    reportMissingDependencies(
      deps,
      ignoredTypes,
      ignoreTypesInPackages,
      targetFile,
      throwOnMissingDependencies,
    );
    if (!allowMultipleRegistrations) {
      validateDuplicateDependencies(deps);
    }

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
    final filteredDeps = generateForEnvironments.isEmpty
        ? deps
        : deps
              .where(
                (element) =>
                    element.environments.isEmpty ||
                    element.environments.any(
                      (e) => generateForEnvironments.contains(e),
                    ),
              )
              .toList();
    final generator = LibraryGenerator(
      dependencies: List.of(filteredDeps),
      generateAccessors: generateAccessors,
      targetFile: preferRelativeImports ? targetFile : null,
      initializerName: initializerName,
      asExtension: asExtension,
      microPackageName: isMicroPackage
          ? buildStep.asset.packageName?.pascalCase
          : null,
      microPackagesModulesBefore: microPackageModulesBefore,
      microPackagesModulesAfter: microPackageModulesAfter,
      usesConstructorCallback: usesConstructorCallback,
      allowMultipleRegistrations: allowMultipleRegistrations,
    );

    final generatedLib = generator.generate();
    final emitter = DartEmitter(
      allocator: HashedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: usesNullSafety,
    );

    final output = DartFormatter(
      languageVersion: DartFormatter.latestShortStyleLanguageVersion,
    ).format(generatedLib.accept(emitter).toString());

    if (isMicroPackage) {
      final outputUri = buildStep.asset.uriWithExtension('.module.dart');
      return buildStep.writeAsString(
        [
          '//@GeneratedMicroModule;${capitalize(buildStep.asset.packageName!.pascalCase)}PackageModule;$outputUri',
          defaultFileHeader,
          output,
        ].join('\n'),
        extension: '.module.dart',
      );
    }
    return output;
  }

  Set<ExternalModuleConfig> _getMicroPackageModules(
    ConstList? constList,
    LeanTypeResolverImpl typeResolver,
  ) {
    return constList?.value.whereType<ConstObject>().map((obj) {
          final typeValue = obj.getTypeRef('module')!.value;
          final scope = obj.getString('scope')?.value;
          throwIf(
            typeValue.element is! ClassElement ||
                !TypeChecker.typeNamed(
                  MicroPackageModule,
                  inPackage: 'injectable',
                ).isSuperOf(typeValue.element!),
            'ExternalPackageModule must be a class that extends MicroPackageModule',
          );
          return ExternalModuleConfig(
            typeResolver.resolveType(typeValue),
            scope,
          );
        }).toSet() ??
        <ExternalModuleConfig>{};
  }

  Set<ExternalModuleConfig> _getMicroPackageModulesMapped(
    ConstList? constList,
    LeanTypeResolverImpl typeResolver,
  ) {
    return constList?.value.whereType<ConstType>().map((e) {
          final typeValue = e.value;
          throwIf(
            typeValue.element is! ClassElement ||
                !_moduleChecker.isSuperOf(typeValue.element!),
            'ExternalPackageModule must be a class that extends MicroPackageModule',
          );
          return ExternalModuleConfig(typeResolver.resolveType(typeValue));
        }).toSet() ??
        <ExternalModuleConfig>{};
  }
}
