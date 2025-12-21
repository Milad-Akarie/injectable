import 'dart:convert';

import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:lean_builder/test.dart';
import 'package:lean_builder/type.dart';
import 'package:test/test.dart';
import 'package:injectable_generator/lean_builder/lean_injectable_builder.dart';
import 'package:lean_builder/builder.dart';

void main() {
  group('LeanInjectableBuilder', () {
    test('constructor sets autoRegister and matchers', () {
      final options = BuilderOptions({
        'auto_register': true,
        'class_name_pattern': '^Injectable.*',
        'file_name_pattern': '.*_injectable\\.dart\$',
      });
      final builder = LeanInjectableBuilder(options);
      expect(builder.autoRegister, isTrue);
      expect(builder.classNameMatcher, isNotNull);
      expect(builder.fileNameMatcher, isNotNull);
    });

    test('shouldBuildFor returns true for Dart source with classes', () {
      final builder = LeanInjectableBuilder(BuilderOptions({}));
      final candidate = BuildCandidate(StringAsset('', fileName: 'path.dart'), true, [
        ExportedSymbol('A', ReferenceType.$class),
      ]);
      expect(builder.shouldBuildFor(candidate), isTrue);
    });

    test('shouldBuildFor returns false otherwise', () {
      final builder = LeanInjectableBuilder(BuilderOptions({}));
      final candidate = BuildCandidate(StringAsset('', fileName: 'path.txt'), false, []);
      expect(builder.shouldBuildFor(candidate), isFalse);
    });

    test('shouldBuildFor returns false for Dart source with no classes', () {
      final builder = LeanInjectableBuilder(BuilderOptions({}));
      final candidate = BuildCandidate(StringAsset('', fileName: 'path.dart'), true, []);
      expect(builder.shouldBuildFor(candidate), isFalse);
    });

    test('outputExtensions returns correct extension', () {
      final builder = LeanInjectableBuilder(BuilderOptions({}));
      expect(builder.outputExtensions, contains('.injectable.ln.json'));
    });

    test('build processes library and generates output', () async {
      final builder = LeanInjectableBuilder(BuilderOptions({}));
      final asset = StringAsset(
        '''
        import 'package:injectable/injectable.dart';
        @injectable
        class MyService {}
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(
        asset,
        allowedExtensions: builder.outputExtensions,
        includePackages: {'injectable'},
      );

      await builder.build(buildStep);
      expect(buildStep.output?.content, isNotNull);
      expect(buildStep.output?.shortUri, asset.uriWithExtension('.injectable.ln.json'));
      final type = ImportableType(name: 'MyService', import: asset.shortUri.toString());
      expect(
        buildStep.output?.content,
        jsonEncode([
          DependencyConfig(
            type: type,
            typeImpl: type,
            injectableType: InjectableType.factory,
          ),
        ]),
      );
    });
  });
}
