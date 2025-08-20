import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:source_gen/source_gen.dart';

import '../models/dependency_config.dart';
import '../resolvers/pubspec_local_package_dependencies_resolver.dart';
import '../utils.dart';

class InjectableHolisticGenerator extends GeneratorForAnnotation<PackageDependenciesLoader> {
  RegExp? _classNameMatcher, _fileNameMatcher;
  final bool _autoRegister;

  late final String _bootstrapMicroModuleName;

  static const _matchesMultiplePeriods = r'.*\..*\.+.*';

  InjectableHolisticGenerator(Map options) : _autoRegister = options['auto_register'] ?? false {
    if (_autoRegister) {
      if (options['class_name_pattern'] != null) {
        _classNameMatcher = RegExp(options['class_name_pattern']);
      }
      if (options['file_name_pattern'] != null) {
        _fileNameMatcher = RegExp(options['file_name_pattern']);
      }
    }
  }

  @override
  Future<String?> generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    throwIf(
      element.library2 == null,
      'Annotated Element is null',
    );

    final libraryElement = element.library2!;
    final maybeBootstrapMicroModuleName = _resolveMicroModuleName(libraryElement);

    throwIf(
      maybeBootstrapMicroModuleName == null,
      'Could not resolve micro module name of package dependencies loader',
    );

    _bootstrapMicroModuleName = maybeBootstrapMicroModuleName!;

    final pubspecAssetId = AssetId(_bootstrapMicroModuleName, 'pubspec.yaml');

    throwIf(
      (await buildStep.canRead(pubspecAssetId)) == false,
      'Cannot read asset: $pubspecAssetId',
    );

    final microModulesToLibraryElements = await _resolveLibraryElementsInMicroModules(
      PubspecLocalPackageDependenciesResolver(
        await buildStep.readAsString(pubspecAssetId),
      ).resolvedDependencies
        ..add(_bootstrapMicroModuleName),
    );

    final allLibraryElements = microModulesToLibraryElements.values.flattened.toList();

    final dependencyConfigs = (await Stream.fromIterable(allLibraryElements)
            .asyncMap(
              (libraryElement) => generateDependenciesJson(
                library: LibraryReader(libraryElement),
                libs: allLibraryElements,
                autoRegister: _autoRegister,
                classNameMatcher: _classNameMatcher,
                fileNameMatcher: _fileNameMatcher,
              ),
            )
            .toList() as Iterable<Iterable<DependencyConfig>>)
        .flattenedToList;

    return dependencyConfigs.isNotEmpty ? jsonEncode(dependencyConfigs) : null;
  }

  // Will return a map associating micro module names (key) to the corresponding list of library elements.
  Future<Map<String, List<LibraryElement2>>> _resolveLibraryElementsInMicroModules(
      Iterable<String> microModules) async {
    final microModuleToLibraryElements = <String, List<LibraryElement2>>{};
    for (final microModule in microModules) {
      final glob = Glob('**.dart');

      final allDartFilePathsInModule = await glob
          .list(
            root: current.replaceFirst('/$_bootstrapMicroModuleName', '/$microModule/lib'),
          )
          .map((fileSystemEntity) => fileSystemEntity.path)
          .where((path) => path.contains(RegExp(_matchesMultiplePeriods)) == false)
          .toList();

      microModuleToLibraryElements[microModule] = [];

      final analysisContextCollection = AnalysisContextCollection(includedPaths: allDartFilePathsInModule);

      AnalysisSession? currentAnalysisSession;
      for (final dartFilePath in allDartFilePathsInModule) {
        currentAnalysisSession ??= analysisContextCollection.contextFor(dartFilePath).currentSession;

        final maybeResolvedLibraryResult = await currentAnalysisSession.getResolvedLibrary(dartFilePath);
        if (maybeResolvedLibraryResult is! ResolvedLibraryResult) {
          throw 'Could not parse unit from path $dartFilePath in analysis session';
        }

        microModuleToLibraryElements[microModule]!.add(maybeResolvedLibraryResult.element2);
      }
    }
    return microModuleToLibraryElements;
  }

  String? _resolveMicroModuleName(LibraryElement2 libraryElement) {
    throwIf(
      libraryElement.firstFragment.libraryFragment == null,
      'Library Fragment of $libraryElement is null',
    );

    final uri = libraryElement.firstFragment.libraryFragment!.source.uri;

    if (uri.scheme != 'package') {
      return null;
    }

    return uri.pathSegments.first;
  }
}
