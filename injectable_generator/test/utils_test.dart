import 'package:analyzer/dart/element/type.dart';
import 'package:injectable_generator/resolvers/utils.dart';
import 'package:injectable_generator/utils.dart';
import 'package:test/test.dart';

// Mock DartType for testing
class MockDartType implements DartType {
  final String displayString;

  MockDartType(this.displayString);

  @override
  String getDisplayString({bool withNullability = true}) => displayString;

  // Implement other required methods with defaults
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('capitalize', () {
    test('should capitalize first letter', () {
      expect(capitalize('hello'), equals('Hello'));
    });

    test('should handle already capitalized string', () {
      expect(capitalize('Hello'), equals('Hello'));
    });

    test('should handle single character', () {
      expect(capitalize('a'), equals('A'));
    });

    test('should handle empty string', () {
      expect(capitalize(''), equals(''));
    });

    test('should handle uppercase string', () {
      expect(capitalize('HELLO'), equals('HELLO'));
    });

    test('should handle mixed case', () {
      expect(capitalize('hELLO'), equals('HELLO'));
    });
  });

  group('toCamelCase', () {
    test('should convert first letter to lowercase', () {
      expect(toCamelCase('Hello'), equals('hello'));
    });

    test('should handle already camelCase string', () {
      expect(toCamelCase('hello'), equals('hello'));
    });

    test('should handle single character', () {
      expect(toCamelCase('A'), equals('a'));
    });

    test('should handle empty string', () {
      expect(toCamelCase(''), equals(''));
    });

    test('should handle PascalCase', () {
      expect(toCamelCase('HelloWorld'), equals('helloWorld'));
    });

    test('should handle all caps', () {
      expect(toCamelCase('HELLO'), equals('hELLO'));
    });
  });

  group('throwBoxed', () {
    test('should throw formatted error message', () {
      expect(
        () => throwBoxed('Test error'),
        throwsA(
          isA<String>().having(
            (e) => e.toString(),
            'message',
            contains('Test error'),
          ),
        ),
      );
    });

    test('should include header in error', () {
      expect(
        () => throwBoxed('Error message'),
        throwsA(
          isA<String>().having(
            (e) => e.toString(),
            'header',
            contains('Injectable Generator'),
          ),
        ),
      );
    });
  });

  group('throwSourceError', () {
    test('should throw formatted source error', () {
      expect(
        () => throwSourceError('Source error'),
        throwsA(
          isA<String>().having(
            (e) => e.toString(),
            'message',
            contains('Source error'),
          ),
        ),
      );
    });

    test('should include header in source error', () {
      expect(
        () => throwSourceError('Error'),
        throwsA(
          isA<String>().having(
            (e) => e.toString(),
            'header',
            contains('Injectable Generator'),
          ),
        ),
      );
    });
  });

  group('throwError', () {
    test('should throw InvalidGenerationSourceError', () {
      expect(
        () => throwError('Error message'),
        throwsA(isA<Exception>()),
      );
    });

    test('should include message in error', () {
      try {
        throwError('Test error message');
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('Test error message'));
      }
    });
  });

  group('throwIf', () {
    test('should throw when condition is true', () {
      expect(
        () => throwIf(true, 'Condition met'),
        throwsA(isA<Exception>()),
      );
    });

    test('should not throw when condition is false', () {
      expect(
        () => throwIf(false, 'Condition not met'),
        returnsNormally,
      );
    });

    test('should include message when throwing', () {
      try {
        throwIf(true, 'Conditional error');
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('Conditional error'));
      }
    });
  });

  group('Iterable extension', () {
    test('firstWhereOrNull should return first matching element', () {
      final list = [1, 2, 3, 4, 5];
      final result = list.firstWhereOrNull((e) => e > 3);
      expect(result, equals(4));
    });

    test('firstWhereOrNull should return null when no match', () {
      final list = [1, 2, 3];
      final result = list.firstWhereOrNull((e) => e > 10);
      expect(result, isNull);
    });

    test('firstWhereOrNull should return first when multiple matches', () {
      final list = [1, 2, 3, 4, 5];
      final result = list.firstWhereOrNull((e) => e > 2);
      expect(result, equals(3));
    });

    test('firstWhereOrNull should work with empty list', () {
      final list = <int>[];
      final result = list.firstWhereOrNull((e) => e > 0);
      expect(result, isNull);
    });

    test('firstWhereOrNull should work with strings', () {
      final list = ['apple', 'banana', 'cherry'];
      final result = list.firstWhereOrNull((e) => e.startsWith('b'));
      expect(result, equals('banana'));
    });
  });

  group('DartType extension', () {
    test('nameWithoutSuffix should remove nullable suffix', () {
      final type = MockDartType('String?');
      expect(type.nameWithoutSuffix, equals('String'));
    });

    test('nameWithoutSuffix should keep non-nullable type as is', () {
      final type = MockDartType('String');
      expect(type.nameWithoutSuffix, equals('String'));
    });

    test(
      'nameWithoutSuffix should handle complex types with nullable suffix',
      () {
        final type = MockDartType('Map<String, int>?');
        expect(type.nameWithoutSuffix, equals('Map<String, int>'));
      },
    );

    test('nameWithoutSuffix should handle generic types without suffix', () {
      final type = MockDartType('List<String>');
      expect(type.nameWithoutSuffix, equals('List<String>'));
    });

    test('nameWithoutSuffix should handle nested generics with nullable', () {
      final type = MockDartType('Future<List<String>>?');
      expect(type.nameWithoutSuffix, equals('Future<List<String>>'));
    });

    test('nameWithoutSuffix should handle single character with suffix', () {
      final type = MockDartType('T?');
      expect(type.nameWithoutSuffix, equals('T'));
    });

    test('nameWithoutSuffix should handle empty string', () {
      final type = MockDartType('');
      expect(type.nameWithoutSuffix, equals(''));
    });

    test(
      'nameWithoutSuffix should handle type ending with multiple question marks',
      () {
        final type = MockDartType('String??');
        expect(type.nameWithoutSuffix, equals('String?'));
      },
    );
  });
}
