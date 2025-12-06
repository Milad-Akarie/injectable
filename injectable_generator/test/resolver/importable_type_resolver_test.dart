import 'package:injectable_generator/resolvers/importable_type_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('ImportableTypeResolver', () {
    group('relative', () {
      test('returns null when path is null', () {
        final result = ImportableTypeResolver.relative(
          null,
          Uri.parse('package:my_package/lib/main.dart'),
        );
        expect(result, isNull);
      });

      test('returns null when to is null', () {
        final result = ImportableTypeResolver.relative(
          'package:my_package/lib/source.dart',
          null,
        );
        expect(result, isNull);
      });

      test('returns filename when package paths are identical', () {
        final result = ImportableTypeResolver.relative(
          'package:my_package/lib/source.dart',
          Uri.parse('package:my_package/lib/source.dart'),
        );
        expect(result, 'source.dart');
      });

      test('returns relative path for same package different files', () {
        final result = ImportableTypeResolver.relative(
          'package:my_package/lib/models/user.dart',
          Uri.parse('package:my_package/lib/main.dart'),
        );
        expect(result, isNotNull);
        expect(result, contains('models/user.dart'));
      });

      test('returns original path for different packages', () {
        final result = ImportableTypeResolver.relative(
          'package:other_package/lib/source.dart',
          Uri.parse('package:my_package/lib/main.dart'),
        );
        expect(result, 'package:other_package/lib/source.dart');
      });

      test('returns original path when schemes do not match package criteria', () {
        final result = ImportableTypeResolver.relative(
          'dart:core',
          Uri.parse('package:my_package/lib/main.dart'),
        );
        expect(result, 'dart:core');
      });

      test('handles asset scheme with non-package file uri', () {
        final result = ImportableTypeResolver.relative(
          'file:///some/path/source.dart',
          Uri.parse('asset:my_package/lib/main.dart'),
        );
        expect(result, isNotNull);
      });

      test('returns path for asset scheme when fileUri is package', () {
        final result = ImportableTypeResolver.relative(
          'package:my_package/lib/source.dart',
          Uri.parse('asset:my_package/lib/main.dart'),
        );
        expect(result, 'package:my_package/lib/source.dart');
      });
    });

    group('resolveAssetImport', () {
      test('returns null when path is null', () {
        final result = ImportableTypeResolver.resolveAssetImport(null);
        expect(result, isNull);
      });

      test('returns path with leading slash for asset scheme', () {
        final result = ImportableTypeResolver.resolveAssetImport(
          'asset:my_package/lib/source.dart',
        );
        expect(result, '/my_package/lib/source.dart');
      });

      test('returns original path for non-asset scheme', () {
        final result = ImportableTypeResolver.resolveAssetImport(
          'package:my_package/lib/source.dart',
        );
        expect(result, 'package:my_package/lib/source.dart');
      });
    });
  });
}
