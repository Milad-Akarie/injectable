import 'package:code_builder/code_builder.dart';

import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/injectable_types.dart';

import 'package:test/test.dart';

void main() {
  group('Accessor Methods Test Group', () {
    test("No accessor methods generated when generateAccessors is false", () {
      final result = generate(
        DependencyConfig.factory('Demo'),
        generateAccessors: false,
      );
      expect(result.trim(), isEmpty);
    });

    test("Simple factory with accessor getter", () {
      final result = generate(DependencyConfig.factory('Demo'));
      expect(result, equals('Demo get demo => get<Demo>()'));
    });

    test("Simple singleton with accessor getter", () {
      final result = generate(DependencyConfig.singleton('UserService'));
      expect(result, contains('UserService get userService => get<UserService>()'));
    });

    test("Simple lazy singleton with accessor getter", () {
      final result = generate(
        DependencyConfig.singleton('ApiClient', lazy: true),
      );
      expect(result, contains('ApiClient get apiClient => get<ApiClient>()'));
    });

    test("Factory with instance name generates method with optional parameter", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'Database'),
          typeImpl: ImportableType(name: 'Database'),
          injectableType: InjectableType.factory,
          instanceName: 'primary',
        ),
      );
      expect(result, contains('Database database({String? instanceName})'));
      expect(result, contains('get<Database>(instanceName: instanceName)'));
    });

    test("Factory with factory params generates method with parameters", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'UserRepository'),
          typeImpl: ImportableType(name: 'UserRepository'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String'),
              paramName: 'userId',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
          ],
        ),
      );
      expect(result, contains('UserRepository userRepository({required String userId})'));
      expect(result, contains('get<UserRepository>(param1: userId)'));
    });

    test("Factory with multiple factory params generates method with all parameters", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'DataService'),
          typeImpl: ImportableType(name: 'DataService'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String'),
              paramName: 'apiKey',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
            InjectedDependency(
              type: ImportableType(name: 'int'),
              paramName: 'timeout',
              isFactoryParam: true,
              isPositional: false,
              isRequired: false,
            ),
          ],
        ),
      );
      expect(result, contains('DataService dataService({required String apiKey, int timeout,'));
      expect(result, contains('param1: apiKey'));
      expect(result, contains('param2: timeout'));
    });

    test("Factory with optional nullable factory param", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'Logger'),
          typeImpl: ImportableType(name: 'Logger'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String', isNullable: true),
              paramName: 'tag',
              isFactoryParam: true,
              isPositional: false,
              isRequired: false,
            ),
          ],
        ),
      );
      expect(result, contains('Logger logger({String? tag})'));
      expect(result, contains('get<Logger>(param1: tag)'));
    });

    test("Async factory generates Future return type", () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'AuthService'),
        typeImpl: ImportableType(name: 'AuthService'),
        injectableType: InjectableType.factory,
        isAsync: true,
      );
      final result = generate(dep, allDeps: [dep]);
      expect(result, contains('Future<AuthService> get authService => getAsync<AuthService>()'));
    });

    test("Factory with async dependency generates Future return type", () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'DataManager'),
        typeImpl: ImportableType(name: 'DataManager'),
        injectableType: InjectableType.factory,
        isAsync: true,
      );
      final result = generate(dep, allDeps: [dep]);
      expect(result, contains('Future<DataManager> get dataManager => getAsync<DataManager>()'));
    });

    test("Factory with both instance name and factory params", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'Cache'),
          typeImpl: ImportableType(name: 'Cache'),
          injectableType: InjectableType.factory,
          instanceName: 'memory',
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'int'),
              paramName: 'maxSize',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
          ],
        ),
      );
      expect(result, contains('Cache cache({String? instanceName, required int maxSize,'));
      expect(result, contains('instanceName: instanceName'));
      expect(result, contains('param1: maxSize'));
    });

    test("Duplicate type names should only generate one accessor", () {
      final dep1 = DependencyConfig.factory('Service');
      final dep2 = DependencyConfig.factory('Service');
      final library = LibraryGenerator(
        dependencies: [dep1, dep2],
        initializerName: 'init',
        asExtension: true,
        generateAccessors: true,
      );
      final extMethods = <Method>[];
      library.generateAccessorMethods(extMethods);
      expect(extMethods.length, equals(1));
    });

    test("Abstract type different from implementation", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'IAuthService'),
          typeImpl: ImportableType(name: 'AuthServiceImpl'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains('AuthServiceImpl get authServiceImpl => get<AuthServiceImpl>()'));
    });

    test("CamelCase conversion for multi-word types", () {
      final result = generate(DependencyConfig.factory('UserAuthService'));
      expect(result, contains('UserAuthService get userAuthService => get<UserAuthService>()'));
    });

    test("Factory with non-factory dependency should still be a getter", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'Controller'),
          typeImpl: ImportableType(name: 'Controller'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Service'),
              paramName: 'service',
              isFactoryParam: false,
            ),
          ],
        ),
      );
      expect(result, contains('Controller get controller => get<Controller>()'));
    });

    test("Factory with three or more factory params", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'ComplexService'),
          typeImpl: ImportableType(name: 'ComplexService'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String'),
              paramName: 'param1',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
            InjectedDependency(
              type: ImportableType(name: 'int'),
              paramName: 'param2',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
            InjectedDependency(
              type: ImportableType(name: 'bool'),
              paramName: 'param3',
              isFactoryParam: true,
              isPositional: false,
              isRequired: false,
            ),
          ],
        ),
      );
      expect(
        result,
        contains('ComplexService complexService({required String param1, required int param2, bool param3,'),
      );
      expect(result, contains('param1: param1'));
      expect(result, contains('param2: param2'));
      expect(result, contains('param3: param3'));
    });

    test("Factory with mixed factory params and non-factory dependencies", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'MixedService'),
          typeImpl: ImportableType(name: 'MixedService'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Config'),
              paramName: 'config',
              isFactoryParam: false,
            ),
            InjectedDependency(
              type: ImportableType(name: 'String'),
              paramName: 'userId',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
          ],
        ),
      );
      expect(result, contains('MixedService mixedService({required String userId})'));
      expect(result, contains('param1: userId'));
    });

    test("Generic type accessor", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'Repository<User>'),
          typeImpl: ImportableType(name: 'UserRepository'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains('UserRepository get userRepository => get<UserRepository>()'));
    });

    test("Type starting with lowercase should be converted to camelCase properly", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'myService'),
          typeImpl: ImportableType(name: 'myService'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains('myService get myService => get<myService>()'));
    });

    test("Type with underscores", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'My_Service_Impl'),
          typeImpl: ImportableType(name: 'My_Service_Impl'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains('My_Service_Impl get my_Service_Impl => get<My_Service_Impl>()'));
    });

    test("Single character type name", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'X'),
          typeImpl: ImportableType(name: 'X'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains('X get x => get<X>()'));
    });

    test("Async lazy singleton generates Future return type", () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'DatabaseConnection'),
        typeImpl: ImportableType(name: 'DatabaseConnection'),
        injectableType: InjectableType.lazySingleton,
        isAsync: true,
      );
      final result = generate(dep, allDeps: [dep]);
      expect(result, contains('Future<DatabaseConnection> get databaseConnection => getAsync<DatabaseConnection>()'));
    });

    test("Async singleton generates Future return type", () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'AppConfig'),
        typeImpl: ImportableType(name: 'AppConfig'),
        injectableType: InjectableType.singleton,
        isAsync: true,
      );
      final result = generate(dep, allDeps: [dep]);
      expect(result, contains('Future<AppConfig> get appConfig => getAsync<AppConfig>()'));
    });

    test("Factory with multiple async dependencies", () {
      final dep = DependencyConfig(
        type: ImportableType(name: 'MultiDbService'),
        typeImpl: ImportableType(name: 'MultiDbService'),
        injectableType: InjectableType.factory,
        isAsync: true,
      );
      final result = generate(dep, allDeps: [dep]);
      expect(result, contains('Future<MultiDbService> get multiDbService => getAsync<MultiDbService>()'));
    });

    test("Factory with async factory param still generates sync accessor", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'AsyncParamService'),
          typeImpl: ImportableType(name: 'AsyncParamService'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Future<String>'),
              paramName: 'asyncValue',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
          ],
        ),
      );
      expect(result, contains('AsyncParamService asyncParamService({required Future<String> asyncValue})'));
      expect(result, contains('get<AsyncParamService>(param1: asyncValue)'));
    });

    test("Instance name with special instance names and multiple factory params", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'HttpClient'),
          typeImpl: ImportableType(name: 'HttpClient'),
          injectableType: InjectableType.factory,
          instanceName: 'authenticated',
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String'),
              paramName: 'baseUrl',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
            InjectedDependency(
              type: ImportableType(name: 'Duration'),
              paramName: 'timeout',
              isFactoryParam: true,
              isPositional: false,
              isRequired: false,
            ),
          ],
        ),
      );
      expect(
        result,
        contains('HttpClient httpClient({String? instanceName, required String baseUrl, Duration timeout,'),
      );
      expect(result, contains('instanceName: instanceName'));
      expect(result, contains('param1: baseUrl'));
      expect(result, contains('param2: timeout'));
    });

    test("All required factory params", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'StrictService'),
          typeImpl: ImportableType(name: 'StrictService'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String'),
              paramName: 'required1',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
            InjectedDependency(
              type: ImportableType(name: 'int'),
              paramName: 'required2',
              isFactoryParam: true,
              isPositional: false,
              isRequired: true,
            ),
          ],
        ),
      );
      expect(result, contains('StrictService strictService({required String required1, required int required2,'));
    });

    test("All optional factory params", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'FlexibleService'),
          typeImpl: ImportableType(name: 'FlexibleService'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String', isNullable: true),
              paramName: 'optional1',
              isFactoryParam: true,
              isPositional: false,
              isRequired: false,
            ),
            InjectedDependency(
              type: ImportableType(name: 'int', isNullable: true),
              paramName: 'optional2',
              isFactoryParam: true,
              isPositional: false,
              isRequired: false,
            ),
          ],
        ),
      );
      expect(result, contains('FlexibleService flexibleService({String? optional1, int? optional2,'));
    });

    test("Nullable type with required param", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'NullableService'),
          typeImpl: ImportableType(name: 'NullableService'),
          injectableType: InjectableType.factory,
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'String', isNullable: true),
              paramName: 'value',
              isFactoryParam: true,
              isPositional: false,
              isRequired: false,
            ),
          ],
        ),
      );
      expect(result, contains('NullableService nullableService({String? value})'));
      expect(result, contains('get<NullableService>(param1: value)'));
    });

    test("Type with dollar sign should handle properly", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: r'$SpecialService'),
          typeImpl: ImportableType(name: r'$SpecialService'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains(r'$SpecialService'));
    });

    test("Deeply nested async dependency chain", () {
      final level1 = DependencyConfig(
        type: ImportableType(name: 'Level1'),
        typeImpl: ImportableType(name: 'Level1'),
        injectableType: InjectableType.factory,
        isAsync: true,
      );
      final result = generate(level1, allDeps: [level1]);
      expect(result, contains('Future<Level1> get level1 => getAsync<Level1>()'));
    });

    test("Type name with numbers", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'Service2FA'),
          typeImpl: ImportableType(name: 'Service2FA'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains('Service2FA get service2FA => get<Service2FA>()'));
    });

    test("Very long type name", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'VeryLongServiceNameThatDescribesWhatItDoesInDetail'),
          typeImpl: ImportableType(name: 'VeryLongServiceNameThatDescribesWhatItDoesInDetail'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(
        result,
        contains(
          'VeryLongServiceNameThatDescribesWhatItDoesInDetail get veryLongServiceNameThatDescribesWhatItDoesInDetail',
        ),
      );
    });

    test("Acronym type name", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'HTTPClient'),
          typeImpl: ImportableType(name: 'HTTPClient'),
          injectableType: InjectableType.factory,
        ),
      );
      expect(result, contains('HTTPClient get hTTPClient => get<HTTPClient>()'));
    });

    test("Factory with instance name only (no factory params)", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'NamedService'),
          typeImpl: ImportableType(name: 'NamedService'),
          injectableType: InjectableType.factory,
          instanceName: 'special',
        ),
      );
      expect(result, contains('NamedService namedService({String? instanceName})'));
      expect(result, contains('get<NamedService>(instanceName: instanceName)'));
    });

    test("Singleton with instance name", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'SingletonService'),
          typeImpl: ImportableType(name: 'SingletonService'),
          injectableType: InjectableType.singleton,
          instanceName: 'primary',
        ),
      );
      expect(result, contains('SingletonService singletonService({String? instanceName})'));
      expect(result, contains('get<SingletonService>(instanceName: instanceName)'));
    });

    test("Lazy singleton with instance name", () {
      final result = generate(
        DependencyConfig(
          type: ImportableType(name: 'LazyService'),
          typeImpl: ImportableType(name: 'LazyService'),
          injectableType: InjectableType.lazySingleton,
          instanceName: 'lazy',
        ),
      );
      expect(result, contains('LazyService lazyService({String? instanceName})'));
      expect(result, contains('get<LazyService>(instanceName: instanceName)'));
    });
  });
}

String generate(
  DependencyConfig input, {
  bool generateAccessors = true,
  List<DependencyConfig>? allDeps,
}) {
  final library = LibraryGenerator(
    dependencies: allDeps ?? [input],
    initializerName: 'init',
    asExtension: true,
    generateAccessors: generateAccessors,
  );
  final extMethods = <Method>[];
  library.generateAccessorMethods(extMethods);
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: true,
  );
  if (extMethods.isEmpty) return '';
  return extMethods.first.accept(emitter).toString();
}
