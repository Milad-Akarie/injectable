import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/dispose_function_config.dart';
import 'package:injectable_generator/models/external_module_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('Library test group', () {
    test("Simple init function", () {
      expect(generate([DependencyConfig.factory('Demo')]), '''
// ignore_for_file: type=lint
// coverage:ignore-file

// initializes the registration of main-scope dependencies inside of GetIt
GetIt init(
  GetIt getIt, {
  String environment,
  EnvironmentFilter environmentFilter,
}) {
  final gh = GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  gh.factory<Demo>(() => Demo());
  return getIt;
}
''');
    });

    test("Simple asExtension init", () {
      expect(generate([DependencyConfig.factory('Demo')], asExt: true), '''
// ignore_for_file: type=lint
// coverage:ignore-file

extension GetItInjectableX on GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  GetIt init({
    String environment,
    EnvironmentFilter environmentFilter,
  }) {
    final gh = GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<Demo>(() => Demo());
    return this;
  }
}
''');
    });

    test("Factory with environment generates environment constants", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          injectableType: InjectableType.factory,
          environments: ['dev', 'test'],
        ),
      ]);
      expect(result, contains("const String _dev = 'dev';"));
      expect(result, contains("const String _test = 'test';"));
    });

    test("Const factory generates const instance", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          injectableType: InjectableType.factory,
          canBeConst: true,
        ),
      ]);
      expect(result, contains('gh.factory<Demo>(() => const Demo());'));
    });

    test("Const factory with named constructor", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          injectableType: InjectableType.factory,
          canBeConst: true,
          constructorName: 'named',
        ),
      ]);
      expect(result, contains('gh.factory<Demo>(() => const Demo.named());'));
    });

    test("Scoped dependencies generate scope init method", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          injectableType: InjectableType.factory,
          scope: 'myScope',
        ),
      ]);
      expect(result, contains('initMyScopeScope'));
      expect(result, contains("'myScope'"));
    });

    test("MicroPackage generates class extending MicroPackageModule", () {
      final result = generate(
        [DependencyConfig.factory('Demo')],
        microPackageName: 'auth',
      );
      expect(
        result,
        contains('class AuthPackageModule extends MicroPackageModule'),
      );
    });

    test("Module with abstract method generates override", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'IService'),
          typeImpl: ImportableType(name: 'ServiceImpl'),
          injectableType: InjectableType.factory,
          moduleConfig: ModuleConfig(
            isAbstract: true,
            isMethod: true,
            type: ImportableType(name: 'ServiceModule'),
            initializerName: 'getService',
          ),
        ),
      ]);
      expect(result, contains('class _\$ServiceModule extends ServiceModule'));
      expect(result, contains('@override'));
      expect(result, contains('ServiceImpl getService()'));
    });

    test("Module with abstract getter generates override getter", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'IService'),
          typeImpl: ImportableType(name: 'ServiceImpl'),
          injectableType: InjectableType.factory,
          moduleConfig: ModuleConfig(
            isAbstract: true,
            isMethod: false,
            type: ImportableType(name: 'ServiceModule'),
            initializerName: 'service',
          ),
        ),
      ]);
      expect(result, contains('ServiceImpl get service'));
    });

    test("Module with dependencies includes _getIt field", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'IService'),
          typeImpl: ImportableType(name: 'ServiceImpl'),
          injectableType: InjectableType.factory,
          moduleConfig: ModuleConfig(
            isAbstract: true,
            isMethod: true,
            type: ImportableType(name: 'ServiceModule'),
            initializerName: 'getService',
          ),
          dependencies: [
            InjectedDependency(
              type: ImportableType(name: 'Repository'),
              paramName: 'repo',
              isFactoryParam: false,
              isPositional: true,
            ),
          ],
        ),
      ]);
      expect(result, contains('final GetIt _getIt;'));
      expect(result, contains('_\$ServiceModule(this._getIt)'));
    });

    test("Singleton with instance dispose function", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          injectableType: InjectableType.lazySingleton,
          disposeFunction: DisposeFunctionConfig(
            name: 'dispose',
            isInstance: true,
          ),
        ),
      ]);
      expect(result, contains('dispose: (i) => i.dispose()'));
    });

    test("Singleton with external dispose function", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          injectableType: InjectableType.lazySingleton,
          disposeFunction: DisposeFunctionConfig(
            name: 'disposeDemo',
            isInstance: false,
            importableType: ImportableType(name: 'disposeDemo'),
          ),
        ),
      ]);
      expect(result, contains('dispose: disposeDemo'));
    });

    test("PreResolve factory generates await", () {
      final result = generate([
        DependencyConfig(
          type: ImportableType(name: 'Demo'),
          typeImpl: ImportableType(name: 'Demo'),
          injectableType: InjectableType.factory,
          isAsync: true,
          preResolve: true,
          constructorName: 'create',
        ),
      ]);
      expect(result, contains('await gh.factoryAsync'));
    });

    test("Empty dependency list generates minimal init", () {
      final result = generate([]);
      expect(result, contains('GetItHelper('));
      expect(result, contains('return getIt;'));
    });

    test("With microPackages before and after", () {
      final result = generate(
        [DependencyConfig.factory('Demo')],
        microPackagesModulesBefore: {
          ExternalModuleConfig(
            ImportableType(name: 'AuthModule', import: 'auth.dart'),
          ),
        },
        microPackagesModulesAfter: {
          ExternalModuleConfig(
            ImportableType(name: 'CoreModule', import: 'core.dart'),
          ),
        },
      );
      expect(result, contains('AuthModule().init(gh)'));
      expect(result, contains('CoreModule().init(gh)'));
    });

    test("Accessor methods are generated when enabled", () {
      final result = generate(
        [
          DependencyConfig(
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            injectableType: InjectableType.factory,
            instanceName: 'specialDemo',
          ),
        ],
        generateAccessors: true,
      );
      expect(result, contains('Demo demo({String instanceName})'));
      expect(result, contains("instanceName: 'specialDemo'"));
    });

    test("Uses constructor callback when enabled", () {
      final result = generate(
        [DependencyConfig.factory('Demo')],
        usesConstructorCallback: true,
      );
      expect(result, contains('constructorCallback'));
      expect(result, contains('ccb'));
    });
  });
}

String generate(
  List<DependencyConfig> input, {
  bool asExt = false,
  String? microPackageName,
  Set<ExternalModuleConfig> microPackagesModulesBefore = const {},
  Set<ExternalModuleConfig> microPackagesModulesAfter = const {},
  bool generateAccessors = false,
  bool usesConstructorCallback = false,
}) {
  final library = LibraryGenerator(
    dependencies: List.of(input),
    initializerName: 'init',
    asExtension: asExt,
    microPackageName: microPackageName,
    microPackagesModulesBefore: microPackagesModulesBefore,
    microPackagesModulesAfter: microPackagesModulesAfter,
    generateAccessors: generateAccessors,
    usesConstructorCallback: usesConstructorCallback,
  ).generate();
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  return DartFormatter(
    languageVersion: DartFormatter.latestShortStyleLanguageVersion,
  ).format(library.accept(emitter).toString());
}
