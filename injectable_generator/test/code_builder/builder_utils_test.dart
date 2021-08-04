import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:test/test.dart';

void main() {
  group('hasAsyncDependency', () {
    test('should return `false` when there are no dependencies', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
      );
      final allDeps = {dep};
      expect(hasAsyncDependency(dep, allDeps), isFalse);
    });

    test('should return `false` when all deps are not async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          )
        ],
      );
      final allDeps = {
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Fizz'),
          typeImpl: ImportableType(name: 'Fizz'),
          injectableType: InjectableType.factory,
        ),
      };
      expect(hasAsyncDependency(dep, allDeps), isFalse);
    });

    test('should return `false` for a missing dependency', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          )
        ],
      );
      final allDeps = <DependencyConfig>{dep};
      expect(hasAsyncDependency(dep, allDeps), isFalse);
    });

    test('should return `true` when at least one dep is async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
            instanceName: 'buzzImpl',
          ),
        ],
      );
      final allDeps = {
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Fizz'),
          typeImpl: ImportableType(name: 'Fizz'),
          injectableType: InjectableType.factory,
          isAsync: true,
        ),
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          instanceName: 'buzzImpl',
        ),
      };
      expect(hasAsyncDependency(dep, allDeps), isTrue);
    });

    test('should return `true` when a named instance dep is async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
            instanceName: 'buzzImpl',
          ),
        ],
      );
      final allDeps = {
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Fizz'),
          typeImpl: ImportableType(name: 'Fizz'),
          injectableType: InjectableType.factory,
        ),
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          instanceName: 'buzzImpl',
          isAsync: true,
        ),
      };
      expect(hasAsyncDependency(dep, allDeps), isTrue);
    });

    test('should return `true` when a transitive dep is async', () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Fizz'),
            paramName: 'fizz',
          ),
        ],
      );
      final allDeps = {
        dep,
        DependencyConfig(
            type: ImportableType(name: 'Fizz'),
            typeImpl: ImportableType(name: 'Fizz'),
            injectableType: InjectableType.factory,
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Buzz'),
                paramName: 'buzz',
                instanceName: 'buzzImpl',
              ),
            ]),
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          instanceName: 'buzzImpl',
          isAsync: true,
        ),
      };
      expect(hasAsyncDependency(dep, allDeps), isTrue);
    });
  });

  group('isAsyncOrHasAsyncDependency', () {
    test('should return `false` when dep lookup misses', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final allDeps = <DependencyConfig>{};
      expect(isAsyncOrHasAsyncDependency(iDep, allDeps), isFalse);
    });

    test('should return `false` when not async and no deps', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        isAsync: false,
      );
      final allDeps = {dep};
      expect(isAsyncOrHasAsyncDependency(iDep, allDeps), isFalse);
    });

    test('should return `true` when async', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        isAsync: true,
      );
      final allDeps = {dep};
      expect(isAsyncOrHasAsyncDependency(iDep, allDeps), isTrue);
    });

    test('should return `false` when not async and no async deps', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
          )
        ],
      );
      final allDeps = {
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
        )
      };
      expect(isAsyncOrHasAsyncDependency(iDep, allDeps), isFalse);
    });

    test('should return `true` when has an async deps', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Buzz'),
            paramName: 'buzz',
          )
        ],
      );
      final allDeps = {
        dep,
        DependencyConfig(
          type: ImportableType(name: 'Buzz'),
          typeImpl: ImportableType(name: 'Buzz'),
          injectableType: InjectableType.factory,
          isAsync: true,
        )
      };
      expect(isAsyncOrHasAsyncDependency(iDep, allDeps), isTrue);
    });
  });

  group('lookupDependency', () {
    test('should return `null` when dep is not found', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final allDeps = <DependencyConfig>{};
      expect(lookupDependency(iDep, allDeps), isNull);
    });

    test('should find and return dep', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
      );
      final allDeps = {dep};
      expect(lookupDependency(iDep, allDeps), same(dep));
    });

    test('should return `null` when named dep is not found', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        paramName: 'fizz',
        instanceName: 'fizzy',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        instanceName: 'fizzBuzz',
      );
      final allDeps = {dep};
      expect(lookupDependency(iDep, allDeps), isNull);
    });

    test('should find and return named dep', () {
      final iDep = InjectedDependency(
        type: ImportableType(name: 'Fizz'),
        instanceName: 'fizzImpl',
        paramName: 'fizz',
      );
      final dep = DependencyConfig(
        type: ImportableType(name: 'Fizz'),
        typeImpl: ImportableType(name: 'Fizz'),
        injectableType: InjectableType.factory,
        instanceName: 'fizzImpl',
      );
      final allDeps = {dep};
      expect(lookupDependency(iDep, allDeps), same(dep));
    });
  });
}
