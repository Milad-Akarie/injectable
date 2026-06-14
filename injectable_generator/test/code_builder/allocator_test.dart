import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/allocator.dart';
import 'package:test/test.dart';

void main() {
  group('HashedAllocator test group', () {
    test('Same url should always get the same alias', () {
      final allocator = HashedAllocator();
      const url = 'package:example/services/service.dart';
      final first = allocator.allocate(refer('ServiceA', url));
      final second = allocator.allocate(refer('ServiceB', url));
      expect(_aliasOf(first), _aliasOf(second));
    });

    test('Urls with colliding hashes should get different aliases', () {
      // find two urls that fall into the same hash bucket
      final buckets = <int, String>{};
      String? firstUrl, secondUrl;
      for (var i = 0; firstUrl == null; i++) {
        final url = 'package:example/feature_$i/service.dart';
        final bucket = url.hashCode / 1000000 ~/ 1;
        final existing = buckets[bucket];
        if (existing != null) {
          firstUrl = existing;
          secondUrl = url;
        } else {
          buckets[bucket] = url;
        }
      }

      final allocator = HashedAllocator();
      final first = allocator.allocate(refer('Service', firstUrl));
      final second = allocator.allocate(refer('Service', secondUrl!));
      expect(_aliasOf(first), isNot(_aliasOf(second)));
    });

    test('Import directives should match allocated aliases', () {
      final allocator = HashedAllocator();
      final allocated = {
        for (final url in [
          'package:example/a.dart',
          'package:example/b.dart',
          'package:example/c.dart',
        ])
          url: _aliasOf(allocator.allocate(refer('Service', url))),
      };
      final directives = {
        for (final import in allocator.imports) import.url: import.as,
      };
      expect(directives, allocated);
    });

    test('dart:core references should not be prefixed', () {
      final allocator = HashedAllocator();
      expect(allocator.allocate(refer('String', 'dart:core')), 'String');
      expect(allocator.imports, isEmpty);
    });
  });
}

String _aliasOf(String allocated) => allocated.split('.').first;
