import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:injectable_generator/resolvers/dependency_resolver.dart';
import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

Future<ResolvedInput> resolveInput(String sourceFile) async {
  final files = [File(sourceFile)];
  final fileMap = Map<String, String>.fromEntries(
    files.map(
      (f) => MapEntry('pkg|lib/${p.basename(f.path)}', f.readAsStringSync()),
    ),
  );
  return await resolveSources<ResolvedInput>(
    fileMap,
    (resolver) async {
      final assetId = AssetId.parse(fileMap.keys.first);
      final library = await resolver.libraryFor(assetId);
      return ResolvedInput(LibraryReader(library), resolver);
    },
    readAllSourcesFromFilesystem: true,
  );
}

Future<ResolvedInput> resolveRawSource(String source) async {
  final fileMap = Map<String, String>.fromEntries([
    MapEntry('pkg|lib/source.dart', '''
    import 'package:injectable/injectable.dart'
    $source'''),
  ]);
  return await resolveSources<ResolvedInput>(fileMap, (resolver) async {
    final assetId = AssetId.parse(fileMap.keys.first);
    final library = await resolver.libraryFor(assetId);
    return ResolvedInput(LibraryReader(library), resolver);
  });
}

void testRawSource(
  String label, {
  required String source,
  required Map output,
}) {
  test(label, () async {
    final resolvedInput = await resolveRawSource('''
    import 'package:injectable/injectable.dart'
    $source''');
    final importsResolve = ImportableTypeResolverImpl(
      await resolvedInput.resolver.libraries.toList(),
    );
    final generated = DependencyResolver(
      importsResolve,
    ).resolve(resolvedInput.library.classes.first);
    expect(output, generated.toJson());
  });
}

class ResolvedInput {
  final LibraryReader library;
  final Resolver resolver;

  const ResolvedInput(this.library, this.resolver);
}
