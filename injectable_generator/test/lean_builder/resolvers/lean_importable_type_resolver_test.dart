import 'package:injectable_generator/lean_builder/resolvers/lean_importable_type_resolver.dart';
import 'package:lean_builder/test.dart';
import 'package:test/test.dart';

void main() {
  group('LeanTypeResolver', () {
    group('relative', () {
      test('returns null when path is null', () {
        final result = LeanTypeResolver.relative(
          null,
          Uri.parse('package:my_package/lib/main.dart'),
        );
        expect(result, isNull);
      });

      test('returns null when to is null', () {
        final result = LeanTypeResolver.relative(
          'package:my_package/lib/source.dart',
          null,
        );
        expect(result, isNull);
      });

      test('returns filename when package paths are identical', () {
        final result = LeanTypeResolver.relative(
          'package:my_package/lib/source.dart',
          Uri.parse('package:my_package/lib/source.dart'),
        );
        expect(result, 'source.dart');
      });

      test('returns relative path for same package different files', () {
        final result = LeanTypeResolver.relative(
          'package:my_package/lib/models/user.dart',
          Uri.parse('package:my_package/lib/main.dart'),
        );
        expect(result, isNotNull);
        expect(result, contains('models/user.dart'));
      });

      test('returns original path for different packages', () {
        final result = LeanTypeResolver.relative(
          'package:other_package/lib/source.dart',
          Uri.parse('package:my_package/lib/main.dart'),
        );
        expect(result, 'package:other_package/lib/source.dart');
      });

      test(
        'returns original path when schemes do not match package criteria',
        () {
          final result = LeanTypeResolver.relative(
            'dart:core',
            Uri.parse('package:my_package/lib/main.dart'),
          );
          expect(result, 'dart:core');
        },
      );

      test('handles asset scheme with non-package file uri', () {
        final result = LeanTypeResolver.relative(
          'file:///some/path/source.dart',
          Uri.parse('asset:my_package/lib/main.dart'),
        );
        expect(result, isNotNull);
      });

      test('returns path for asset scheme when fileUri is package', () {
        final result = LeanTypeResolver.relative(
          'package:my_package/lib/source.dart',
          Uri.parse('asset:my_package/lib/main.dart'),
        );
        expect(result, 'package:my_package/lib/source.dart');
      });
    });

    group('resolveAssetImport', () {
      test('returns null when path is null', () {
        final result = LeanTypeResolver.resolveAssetImport(null);
        expect(result, isNull);
      });

      test('returns path with leading slash for asset scheme', () {
        final result = LeanTypeResolver.resolveAssetImport(
          'asset:my_package/lib/source.dart',
        );
        expect(result, '/my_package/lib/source.dart');
      });

      test('returns original path for non-asset scheme', () {
        final result = LeanTypeResolver.resolveAssetImport(
          'package:my_package/lib/source.dart',
        );
        expect(result, 'package:my_package/lib/source.dart');
      });
    });
  });

  group('LeanTypeResolverImpl', () {
    test(
      'resolveType returns correct ImportableType for simple class',
      () async {
        final asset = StringAsset(
          '''
        class MyService {}
      ''',
          fileName: 'my_service.dart',
        );

        final buildStep = buildStepForTestAsset(asset);
        final resolver = LeanTypeResolverImpl(buildStep.resolver);

        final library = buildStep.resolver.resolveLibrary(asset);
        final clazz = library.classes.first;

        final result = resolver.resolveType(clazz.thisType);

        expect(result.name, 'MyService');
        expect(result.import, asset.shortUri.toString());
        expect(result.isNullable, false);
      },
    );

    test('resolveType handles nullable types', () async {
      final asset = StringAsset(
        '''
        class MyService {
          String? nullableField;
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;
      final field = clazz.fields.first;

      final result = resolver.resolveType(field.type);

      expect(result.name, 'String');
      expect(result.isNullable, true);
    });

    test('resolveType handles parameterized types', () async {
      final asset = StringAsset(
        '''
        class MyService {
          List<String> items = [];
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;
      final field = clazz.fields.first;

      final result = resolver.resolveType(field.type);

      expect(result.name, 'List');
      expect(result.typeArguments.length, 1);
      expect(result.typeArguments.first.name, 'String');
    });

    test('resolveType handles nested parameterized types', () async {
      final asset = StringAsset(
        '''
        class MyService {
          Map<String, List<int>> data = {};
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;
      final field = clazz.fields.first;

      final result = resolver.resolveType(field.type);

      expect(result.name, 'Map');
      expect(result.typeArguments.length, 2);
      expect(result.typeArguments[0].name, 'String');
      expect(result.typeArguments[1].name, 'List');
      expect(result.typeArguments[1].typeArguments.length, 1);
      expect(result.typeArguments[1].typeArguments.first.name, 'int');
    });

    test('resolveImports returns empty set for core dart types', () async {
      final asset = StringAsset(
        '''
        class MyService {
          String field = '';
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;
      final field = clazz.fields.first;

      final result = resolver.resolveImports(field.type);

      expect(result, isEmpty);
    });

    test('resolveImports returns package import for custom types', () async {
      final asset = StringAsset(
        '''
        class MyService {}
        class OtherService {
          MyService service;
          OtherService(this.service);
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.last;
      final field = clazz.fields.first;

      final result = resolver.resolveImports(field.type);

      expect(result, isNotEmpty);
      expect(result.first, asset.shortUri.toString());
    });

    test('resolveImports handles dart library imports', () async {
      final asset = StringAsset(
        '''
        import 'dart:async';
        class MyService {
          Future<void> method() async {}
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;
      final method = clazz.methods.first;

      final result = resolver.resolveImports(method.returnType);

      expect(result, contains('dart:async'));
    });

    test('resolveFunctionType resolves top-level function', () async {
      final asset = StringAsset(
        '''
        void myFunction() {}
        class MyService {
          void Function() callback;
          MyService(this.callback);
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final function = library.functions.first;

      final result = resolver.resolveFunctionType(
        function.type,
        function,
      );

      expect(result.name, 'myFunction');
      expect(result.import, asset.shortUri.toString());
    });

    test('resolveFunctionType resolves class method', () async {
      final asset = StringAsset(
        '''
        class MyService {
          void myMethod() {}
        }
      ''',
        fileName: 'my_service.dart',
      );

      final buildStep = buildStepForTestAsset(asset);
      final resolver = LeanTypeResolverImpl(buildStep.resolver);

      final library = buildStep.resolver.resolveLibrary(asset);
      final clazz = library.classes.first;
      final method = clazz.methods.first;

      final result = resolver.resolveFunctionType(
        method.type,
        method,
      );

      expect(result.name, 'MyService.myMethod');
      expect(result.import, asset.shortUri.toString());
    });
  });
}
