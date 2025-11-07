import 'package:code_builder/code_builder.dart';
import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/injectable_types.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';
import 'package:injectable_generator/models/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('Factory param generator Test group', () {
    test("One factory param generator test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: true,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, Storage, dynamic>((storage, _, ) => Demo(storage));',
      );
    });

    test("Two factory param generator test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: true,
              ),
              InjectedDependency(
                type: ImportableType(name: 'Url'),
                paramName: 'url',
                isFactoryParam: true,
                isPositional: true,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, Storage, Url>((storage, url, ) => Demo(storage, url, ));',
      );
    });

    test("Two named factory param generator test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: true,
                isPositional: false,
              ),
              InjectedDependency(
                type: ImportableType(name: 'Url'),
                paramName: 'url',
                isFactoryParam: true,
                isPositional: false,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, Storage, Url>((storage, url, ) => Demo(storage: storage, url: url, ));',
      );
    });

    test("One factory param with injected dependencies test", () {
      expect(
        generate(
          DependencyConfig(
            injectableType: InjectableType.factory,
            type: ImportableType(name: 'Demo'),
            typeImpl: ImportableType(name: 'Demo'),
            dependencies: [
              InjectedDependency(
                type: ImportableType(name: 'Storage'),
                paramName: 'storage',
                isFactoryParam: false,
                isPositional: true,
              ),
              InjectedDependency(
                type: ImportableType(name: 'String'),
                paramName: 'url',
                isFactoryParam: true,
                isPositional: true,
              ),
            ],
          ),
        ),
        'gh.factoryParam<Demo, String, dynamic>((url, _, ) => Demo(gh<Storage>(), url, ));',
      );
    });

    test("One factory param with injected async dependencies test", () {
      final dep = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Demo'),
        typeImpl: ImportableType(name: 'Demo'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Storage'),
            paramName: 'storage',
            isFactoryParam: false,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'url',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );
      final allDeps = [
        dep,
        DependencyConfig(
          injectableType: InjectableType.factory,
          type: ImportableType(name: 'Storage'),
          typeImpl: ImportableType(name: 'Storage'),
          isAsync: true,
        ),
      ];
      expect(
        generate(dep, allDeps: allDeps),
        'gh.factoryParamAsync<Demo, String, dynamic>((url, _, ) async  => Demo( await gh.getAsync<Storage>(), url, ));',
      );
    });
  });

  group('Transitive Factory Param Tests', () {
    test("Single level transitive factory param - positional dependency", () {
      // A depends on String (factory param)
      final depA = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'A'),
        typeImpl: ImportableType(name: 'A'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'x',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // B depends on A (which needs String)
      final depB = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'B'),
        typeImpl: ImportableType(name: 'B'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'A'),
            paramName: 'a',
            isFactoryParam: false,
            isPositional: true,
          ),
        ],
      );

      final allDeps = [depA, depB];

      expect(
        generate(depB, allDeps: allDeps),
        'gh.factoryParam<B, String, dynamic>((param1, _, ) => B(gh<A>(param1: param1)));',
      );
    });

    test("Single level transitive factory param - named dependency", () {
      // A depends on String (factory param)
      final depA = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'A'),
        typeImpl: ImportableType(name: 'A'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'x',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // B depends on A (named, which needs String)
      final depB = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'B'),
        typeImpl: ImportableType(name: 'B'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'A'),
            paramName: 'a',
            isFactoryParam: false,
            isPositional: false,
          ),
        ],
      );

      final allDeps = [depA, depB];

      expect(
        generate(depB, allDeps: allDeps),
        'gh.factoryParam<B, String, dynamic>((param1, _, ) => B(a: gh<A>(param1: param1)));',
      );
    });

    test("Multi-level transitive factory params", () {
      // A depends on String (factory param)
      final depA = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'A'),
        typeImpl: ImportableType(name: 'A'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'x',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // B depends on String and int (factory params)
      final depB = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'B'),
        typeImpl: ImportableType(name: 'B'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'b1',
            isFactoryParam: true,
            isPositional: false,
          ),
          InjectedDependency(
            type: ImportableType(name: 'int'),
            paramName: 'b2',
            isFactoryParam: true,
            isPositional: false,
          ),
        ],
      );

      // D depends on String (factory param)
      final depD = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'D'),
        typeImpl: ImportableType(name: 'D'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'g',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // C depends on String (direct factory param), A, B, and D (all need params)
      final depC = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'C'),
        typeImpl: ImportableType(name: 'C'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'x',
            isFactoryParam: true,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'A'),
            paramName: 'a',
            isFactoryParam: false,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'B'),
            paramName: 'b',
            isFactoryParam: false,
            isPositional: false,
          ),
          InjectedDependency(
            type: ImportableType(name: 'D'),
            paramName: 'd',
            isFactoryParam: false,
            isPositional: false,
          ),
        ],
      );

      final allDeps = [depA, depB, depD, depC];

      expect(
        generate(depC, allDeps: allDeps),
        'gh.factoryParam<C, String, int>((x, param2, ) => C(x, gh<A>(param1: x), b: gh<B>(param1: x, param2: param2, ), d: gh<D>(param1: x), ));',
      );
    });

    test("Mixed direct and transitive factory params with unique types", () {
      // Storage has no factory params
      final depStorage = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Storage'),
        typeImpl: ImportableType(name: 'Storage'),
        dependencies: [],
      );

      // Config depends on String (factory param)
      final depConfig = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Config'),
        typeImpl: ImportableType(name: 'Config'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'apiKey',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // Service depends on int (direct factory param), Storage (no params), and Config (needs String)
      final depService = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Service'),
        typeImpl: ImportableType(name: 'Service'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'int'),
            paramName: 'timeout',
            isFactoryParam: true,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'Storage'),
            paramName: 'storage',
            isFactoryParam: false,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'Config'),
            paramName: 'config',
            isFactoryParam: false,
            isPositional: false,
          ),
        ],
      );

      final allDeps = [depStorage, depConfig, depService];

      expect(
        generate(depService, allDeps: allDeps),
        'gh.factoryParam<Service, int, String>((timeout, param2, ) => Service(timeout, gh<Storage>(), config: gh<Config>(param1: param2), ));',
      );
    });

    test("Transitive factory params with async dependencies", () {
      // A depends on String (factory param) and is async
      final depA = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'A'),
        typeImpl: ImportableType(name: 'A'),
        isAsync: true,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'x',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // B depends on A (async, needs String)
      final depB = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'B'),
        typeImpl: ImportableType(name: 'B'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'A'),
            paramName: 'a',
            isFactoryParam: false,
            isPositional: true,
          ),
        ],
      );

      final allDeps = [depA, depB];

      expect(
        generate(depB, allDeps: allDeps),
        'gh.factoryParamAsync<B, String, dynamic>((param1, _, ) async  => B( await gh.getAsync<A>(param1: param1)));',
      );
    });

    test("Preserve original param names for direct params only", () {
      // Helper depends on String (factory param)
      final depHelper = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Helper'),
        typeImpl: ImportableType(name: 'Helper'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'helperName',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // Manager has direct factory param 'id' (int) and depends on Helper (needs String)
      final depManager = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Manager'),
        typeImpl: ImportableType(name: 'Manager'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'int'),
            paramName: 'id',
            isFactoryParam: true,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'Helper'),
            paramName: 'helper',
            isFactoryParam: false,
            isPositional: false,
          ),
        ],
      );

      final allDeps = [depHelper, depManager];

      // Should preserve 'id' (direct param) but use 'param2' for String (from Helper)
      expect(
        generate(depManager, allDeps: allDeps),
        'gh.factoryParam<Manager, int, String>((id, param2, ) => Manager(id, helper: gh<Helper>(param1: param2), ));',
      );
    });

    test("Three level deep transitive factory params", () {
      // Level 1: Logger depends on String
      final depLogger = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Logger'),
        typeImpl: ImportableType(name: 'Logger'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'logLevel',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // Level 2: Database depends on Logger
      final depDatabase = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Database'),
        typeImpl: ImportableType(name: 'Database'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Logger'),
            paramName: 'logger',
            isFactoryParam: false,
            isPositional: true,
          ),
        ],
      );

      // Level 3: Repository depends on Database
      final depRepository = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Repository'),
        typeImpl: ImportableType(name: 'Repository'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Database'),
            paramName: 'db',
            isFactoryParam: false,
            isPositional: false,
          ),
        ],
      );

      final allDeps = [depLogger, depDatabase, depRepository];

      // Repository should get String param transitively through Database -> Logger
      expect(
        generate(depRepository, allDeps: allDeps),
        'gh.factoryParam<Repository, String, dynamic>((param1, _, ) => Repository(db: gh<Database>(param1: param1)));',
      );
    });
  });

  group('Module with Transitive Factory Param Tests', () {
    test("Module method with direct factory param", () {
      final moduleConfig = ModuleConfig(
        isAbstract: true,
        isMethod: true,
        type: ImportableType(name: 'AppModule'),
        initializerName: 'provideService',
      );

      // Service provided by module with String factory param
      final depService = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Service'),
        typeImpl: ImportableType(name: 'Service'),
        moduleConfig: moduleConfig,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'apiKey',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      final allDeps = [depService];

      expect(
        generate(depService, allDeps: allDeps),
        'gh.factoryParam<Service, String, dynamic>((apiKey, _, ) => appModule.provideService(apiKey));',
      );
    });

    test("Module method with multiple factory params", () {
      final moduleConfig = ModuleConfig(
        isAbstract: true,
        isMethod: true,
        type: ImportableType(name: 'NetworkModule'),
        initializerName: 'createClient',
      );

      // Client provided by module with String and int factory params
      final depClient = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'HttpClient'),
        typeImpl: ImportableType(name: 'HttpClient'),
        moduleConfig: moduleConfig,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'baseUrl',
            isFactoryParam: true,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'int'),
            paramName: 'timeout',
            isFactoryParam: true,
            isPositional: false,
          ),
        ],
      );

      final allDeps = [depClient];

      expect(
        generate(depClient, allDeps: allDeps),
        'gh.factoryParam<HttpClient, String, int>((baseUrl, timeout, ) => networkModule.createClient(baseUrl, timeout: timeout, ));',
      );
    });

    test("Module method with factory param and injected dependency", () {
      final moduleConfig = ModuleConfig(
        isAbstract: true,
        isMethod: true,
        type: ImportableType(name: 'AppModule'),
        initializerName: 'provideRepository',
      );

      // Database has no factory params
      final depDatabase = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Database'),
        typeImpl: ImportableType(name: 'Database'),
        dependencies: [],
      );

      // Repository provided by module with String factory param and Database injected
      final depRepository = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Repository'),
        typeImpl: ImportableType(name: 'Repository'),
        moduleConfig: moduleConfig,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'tableName',
            isFactoryParam: true,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'Database'),
            paramName: 'db',
            isFactoryParam: false,
            isPositional: true,
          ),
        ],
      );

      final allDeps = [depDatabase, depRepository];

      expect(
        generate(depRepository, allDeps: allDeps),
        'gh.factoryParam<Repository, String, dynamic>((tableName, _, ) => appModule.provideRepository(tableName, gh<Database>(), ));',
      );
    });

    test("Module method with transitive factory param from injected dependency", () {
      final moduleConfig = ModuleConfig(
        isAbstract: true,
        isMethod: true,
        type: ImportableType(name: 'AppModule'),
        initializerName: 'provideService',
      );

      // Config depends on String (factory param)
      final depConfig = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Config'),
        typeImpl: ImportableType(name: 'Config'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'apiKey',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // Service provided by module, depends on Config (which needs String)
      final depService = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Service'),
        typeImpl: ImportableType(name: 'Service'),
        moduleConfig: moduleConfig,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Config'),
            paramName: 'config',
            isFactoryParam: false,
            isPositional: true,
          ),
        ],
      );

      final allDeps = [depConfig, depService];

      // Service should get String param transitively through Config
      expect(
        generate(depService, allDeps: allDeps),
        'gh.factoryParam<Service, String, dynamic>((param1, _, ) => appModule.provideService(gh<Config>(param1: param1)));',
      );
    });

    test("Module method with mixed direct and transitive factory params", () {
      final moduleConfig = ModuleConfig(
        isAbstract: true,
        isMethod: true,
        type: ImportableType(name: 'AppModule'),
        initializerName: 'provideComplexService',
      );

      // Logger depends on String (factory param)
      final depLogger = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Logger'),
        typeImpl: ImportableType(name: 'Logger'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'logLevel',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // Cache depends on int (factory param)
      final depCache = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Cache'),
        typeImpl: ImportableType(name: 'Cache'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'int'),
            paramName: 'ttl',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // ComplexService provided by module with:
      // - bool direct factory param
      // - Logger dependency (needs String)
      // - Cache dependency (needs int)
      final depComplexService = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'ComplexService'),
        typeImpl: ImportableType(name: 'ComplexService'),
        moduleConfig: moduleConfig,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'bool'),
            paramName: 'enableMetrics',
            isFactoryParam: true,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'Logger'),
            paramName: 'logger',
            isFactoryParam: false,
            isPositional: true,
          ),
          InjectedDependency(
            type: ImportableType(name: 'Cache'),
            paramName: 'cache',
            isFactoryParam: false,
            isPositional: false,
          ),
        ],
      );

      final allDeps = [depLogger, depCache, depComplexService];

      // Should have: bool (direct), String (from Logger), int (from Cache)
      // GetIt factoryParam supports multiple type params
      // The implementation collects all unique transitive types
      expect(
        generate(depComplexService, allDeps: allDeps),
        'gh.factoryParam<ComplexService, bool, String, int>((enableMetrics, param2, param3, ) => appModule.provideComplexService(enableMetrics, gh<Logger>(param1: param2), cache: gh<Cache>(param1: param3), ));',
      );
    });

    test("Module getter (non-method) with factory param dependency", () {
      final moduleConfig = ModuleConfig(
        isAbstract: true,
        isMethod: false, // Getter, not a method
        type: ImportableType(name: 'AppModule'),
        initializerName: 'service',
      );

      // Config depends on String (factory param)
      final depConfig = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Config'),
        typeImpl: ImportableType(name: 'Config'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'apiKey',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // Service provided by module getter (no params can be passed to getter)
      // But it shouldn't have dependencies with factory params
      final depService = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Service'),
        typeImpl: ImportableType(name: 'Service'),
        moduleConfig: moduleConfig,
        dependencies: [],
      );

      final allDeps = [depConfig, depService];

      // Getter has no parameters
      expect(
        generate(depService, allDeps: allDeps),
        'gh.factory<Service>(() => appModule.service);',
      );
    });

    test("Two-level transitive factory params through module dependency", () {
      final moduleConfig = ModuleConfig(
        isAbstract: true,
        isMethod: true,
        type: ImportableType(name: 'AppModule'),
        initializerName: 'provideController',
      );

      // Config depends on String
      final depConfig = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Config'),
        typeImpl: ImportableType(name: 'Config'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'String'),
            paramName: 'apiUrl',
            isFactoryParam: true,
            isPositional: true,
          ),
        ],
      );

      // Service depends on Config
      final depService = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Service'),
        typeImpl: ImportableType(name: 'Service'),
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Config'),
            paramName: 'config',
            isFactoryParam: false,
            isPositional: true,
          ),
        ],
      );

      // Controller provided by module, depends on Service (which needs Config -> String)
      final depController = DependencyConfig(
        injectableType: InjectableType.factory,
        type: ImportableType(name: 'Controller'),
        typeImpl: ImportableType(name: 'Controller'),
        moduleConfig: moduleConfig,
        dependencies: [
          InjectedDependency(
            type: ImportableType(name: 'Service'),
            paramName: 'service',
            isFactoryParam: false,
            isPositional: true,
          ),
        ],
      );

      final allDeps = [depConfig, depService, depController];

      // Controller should get String param transitively: Controller -> Service -> Config -> String
      expect(
        generate(depController, allDeps: allDeps),
        'gh.factoryParam<Controller, String, dynamic>((param1, _, ) => appModule.provideController(gh<Service>(param1: param1)));',
      );
    });
  });
}

String generate(DependencyConfig input, {List<DependencyConfig>? allDeps}) {
  final generator = InitMethodGenerator(
    scopeDependencies: allDeps ?? [],
    allDependencies: DependencyList(dependencies: allDeps ?? []),
    initializerName: 'init',
  );
  final statement = generator.buildLazyRegisterFun(input);
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  return statement.accept(emitter).toString();
}
