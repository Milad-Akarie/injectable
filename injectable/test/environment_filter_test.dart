import 'package:injectable/injectable.dart' as inj;
import 'package:test/test.dart';

void main() {
  group('NoEnvOrContains', () {
    test('should allow registration when dependency has no environment', () {
      final filter = inj.NoEnvOrContains('dev');
      expect(filter.canRegister({}), isTrue);
    });

    test('should allow registration when environment matches', () {
      final filter = inj.NoEnvOrContains('dev');
      expect(filter.canRegister({'dev'}), isTrue);
    });

    test('should allow registration when environment is in set', () {
      final filter = inj.NoEnvOrContains('dev');
      expect(filter.canRegister({'dev', 'prod'}), isTrue);
    });

    test('should reject registration when environment does not match', () {
      final filter = inj.NoEnvOrContains('dev');
      expect(filter.canRegister({'prod'}), isFalse);
    });

    test('should handle null environment', () {
      final filter = inj.NoEnvOrContains(null);
      expect(filter.canRegister({}), isTrue);
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('should store environment in environments set', () {
      final filter = inj.NoEnvOrContains('dev');
      expect(filter.environments, {'dev'});
    });

    test('should have empty environments set when null', () {
      final filter = inj.NoEnvOrContains(null);
      expect(filter.environments, isEmpty);
    });
  });

  group('NoEnvOrContainsAll', () {
    test('should allow registration when dependency has no environment', () {
      final filter = inj.NoEnvOrContainsAll({'dev', 'test'});
      expect(filter.canRegister({}), isTrue);
    });

    test('should allow registration when all environments match', () {
      final filter = inj.NoEnvOrContainsAll({'dev', 'test'});
      expect(filter.canRegister({'dev', 'test'}), isTrue);
    });

    test('should allow registration when dependency has more environments', () {
      final filter = inj.NoEnvOrContainsAll({'dev'});
      expect(filter.canRegister({'dev', 'test', 'prod'}), isTrue);
    });

    test('should reject registration when not all environments match', () {
      final filter = inj.NoEnvOrContainsAll({'dev', 'test'});
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('should reject registration when no environments match', () {
      final filter = inj.NoEnvOrContainsAll({'dev', 'test'});
      expect(filter.canRegister({'prod'}), isFalse);
    });

    test('should handle empty filter environments', () {
      final filter = inj.NoEnvOrContainsAll({});
      expect(filter.canRegister({}), isTrue);
      expect(filter.canRegister({'dev'}), isTrue);
    });

    test('should store environments', () {
      final filter = inj.NoEnvOrContainsAll({'dev', 'test'});
      expect(filter.environments, {'dev', 'test'});
    });
  });

  group('NoEnvOrContainsAny', () {
    test('should allow registration when dependency has no environment', () {
      final filter = inj.NoEnvOrContainsAny({'dev', 'test'});
      expect(filter.canRegister({}), isTrue);
    });

    test('should allow registration when one environment matches', () {
      final filter = inj.NoEnvOrContainsAny({'dev', 'test'});
      expect(filter.canRegister({'dev'}), isTrue);
    });

    test('should allow registration when multiple environments match', () {
      final filter = inj.NoEnvOrContainsAny({'dev', 'test'});
      expect(filter.canRegister({'dev', 'test'}), isTrue);
    });

    test('should allow registration when any environment matches', () {
      final filter = inj.NoEnvOrContainsAny({'dev', 'test'});
      expect(filter.canRegister({'test', 'prod'}), isTrue);
    });

    test('should reject registration when no environments match', () {
      final filter = inj.NoEnvOrContainsAny({'dev', 'test'});
      expect(filter.canRegister({'prod'}), isFalse);
    });

    test(
      'should reject registration when no environments match (multiple)',
      () {
        final filter = inj.NoEnvOrContainsAny({'dev'});
        expect(filter.canRegister({'prod', 'staging'}), isFalse);
      },
    );

    test('should handle empty filter environments', () {
      final filter = inj.NoEnvOrContainsAny({});
      expect(filter.canRegister({}), isTrue);
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('should store environments', () {
      final filter = inj.NoEnvOrContainsAny({'dev', 'test'});
      expect(filter.environments, {'dev', 'test'});
    });
  });

  group('SimpleEnvironmentFilter', () {
    test('should use custom filter function', () {
      final filter = inj.SimpleEnvironmentFilter(
        filter: (depEnvs) => depEnvs.contains('custom'),
      );
      expect(filter.canRegister({'custom'}), isTrue);
      expect(filter.canRegister({'dev'}), isFalse);
    });

    test('should allow complex filter logic', () {
      final filter = inj.SimpleEnvironmentFilter(
        filter: (depEnvs) =>
            depEnvs.isEmpty || (depEnvs.contains('dev') && depEnvs.length == 1),
        environments: {'dev'},
      );
      expect(filter.canRegister({}), isTrue);
      expect(filter.canRegister({'dev'}), isTrue);
      expect(filter.canRegister({'dev', 'test'}), isFalse);
    });

    test('should store environments', () {
      final filter = inj.SimpleEnvironmentFilter(
        filter: (_) => true,
        environments: {'dev', 'prod'},
      );
      expect(filter.environments, {'dev', 'prod'});
    });

    test('should have empty environments by default', () {
      final filter = inj.SimpleEnvironmentFilter(filter: (_) => true);
      expect(filter.environments, isEmpty);
    });
  });

  group('SetX extension', () {
    test('firstOrNull should return first element when set is not empty', () {
      final set = {'a', 'b', 'c'};
      expect(set.firstOrNull, isNotNull);
      expect(set.firstOrNull, 'a');
    });

    test('firstOrNull should return null when set is empty', () {
      final set = <String>{};
      expect(set.firstOrNull, isNull);
    });
  });
}
