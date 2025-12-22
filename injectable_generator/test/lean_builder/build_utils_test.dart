import 'package:injectable_generator/lean_builder/build_utils.dart';
import 'package:lean_builder/builder.dart';
import 'package:test/test.dart';

void main() {
  group('throwIf', () {
    test('throws when condition is true', () {
      expect(
        () => throwIf(true, 'Test error'),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            'Test error',
          ),
        ),
      );
    });

    test('does not throw when condition is false', () {
      expect(() => throwIf(false, 'Should not throw'), returnsNormally);
    });
  });

  group('throwError', () {
    test('always throws InvalidGenerationSourceError', () {
      expect(
        () => throwError('Another error'),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            'Another error',
          ),
        ),
      );
    });
  });
}
