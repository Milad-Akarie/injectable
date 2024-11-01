# ChangeLog
## [2.5.0]
- Chore: update get_it constraint to 7.2.0 <= 9.0.0
- Fix: scope annotation does not work with getters
## [2.4.4]
- Fix: Fix dispose not passed to getIt.registerSingleton
## [2.4.3]
- Feat: Improve Code Generation consistency using hash in alias imports
- Fix: Fix @preResolve only works for methods warning
## [2.4.2]
chore: unpin meta version
## [2.4.1]
Revert: Pin meta version to 1.11.0 so it's compatible with flutter_test
## [2.4.0]
Feat: add @ignoreParam annotation to ignore optional parameters in factory methods
## [2.3.5]
Fix: add generic type annotation to registerSingleton() call #436
## [2.3.4]
- HotFix for Postpone singleton initialisation to respect environment filters
## [2.3.3] (skip)
- Fix Postpone singleton initialisation to respect environment filters by @lrampazzo
## [2.3.2]
- Add option to pass instance callback function to the init function by @Adam-Langley
## [2.3.1]
- Fix PreResolved singletons/factories fail checking environment filters #398
## [2.3.0]
- Added [rootDir] support for specifying the root directory for the generation process.
- Fix Undefined name 'gh'. when generating @InjectableInit() with only microPackageModule #392
## [2.2.0]
- Optimize injectable_generator async analysis by [https://github.com/Jjagg]
- Update dart constrains to ">=3.0.0 <4.0.0"
- Update analyzer constrains to include v6+
## [2.1.2]
- Update dart constrains to ">=2.17.0 <4.0.0"
## [2.1.1]
- add coverage:ignore-file comment to generated config
- fix relative imports not working
## [2.1.0]
- Add support for micro package modules order [before,after]
- Add support for micro package modules scopes
## [2.0.1]
- Fix registration order #324
- Fix some types in readme file
## [2.0.0] [Minor breaking changes]
- Add support for micro packages
- Add support for external package modules
- Add support for manual dependencies ordering thanks to @casvanluijtelaar
- Add support for GetIt scopes
- Add @PostConstruct annotation to execute sync/async code after construction
- Add preResolve to @FactoryMethod annotation              
- Add throwOnMissingDependencies flag to @InjectableInit annotation
- Change asExtension default value to true [breaking change] 
- Change initializerName default value to 'init' [breaking change]
## [1.5.3]
- Sync injectable and injectable_generator with GetIt v7.2.0 to generate non-nullable @factoryParams
- Migrate to analyzer 3.0.0
## [1.5.0]
Use getAsync for async injected dependencies, fixes #230
Add support for function factory params, fixes #224
Update analyzer version #228
Add ignore types in packages support 
Fix some readme typos
## [1.4.1]
- Pomp up build_runner version to 2.0.3
- Fix generator crash when using inline environments #205
## [1.4.0]
- Pomp up get_it version to range to 7.0.0 <= 8.0.0
- Pomp up build_runner version to 2.0.2
## [1.3.0]
- Include merge that fixes #194
- Pomp up versions of build_runner -> 2.0.1, code_builder -> 4.0.0, analyzer -> 1.5.0 
## [1.2.2]
- Fix generator crash after 1.2.1 update
- Add option to ignore missing type warning for specified types
## [1.2.1]
- Pomp up versions of build, build_runner, dart_style and source_gen
- Fix named instances are ignored when sorting dependencies. 
- Clean up some code
## [1.2.0]
- Push nullSafety version to the main section
- Fix sorting by dependents ignores named instances
## [1.2.0-nullsafety]
- add null safety support
## [1.1.2]
- Add support for disposing of singletons.
- change min version constraint of GetIt to 5.0.0
- update readme file
## [1.1.0]
- Refactor code to support null-safety
- Fix preResolved instances conditional registration
- Add option to generate null-safety compatible code to injectableInit
## [1.0.7]
- Fix pre-resolved primitives naming issue #161
- Fix some types in readme file
- Fix environments is already registered issue.
## [1.0.5]
- Add support for get_it ^5.0
- Fix analyzer compatibility issues
## [1.0.4]
- Add option to customize the initializer function name
- Add option to generate the initializer function as an extension
- Change initializer functions returns the passed get_it instance instead of void
- Add Advanced environment filter that can be extended and customized
- Fix Injectable generator not handling multiple instances of generic types #107
## [1.0.2]
- Add option to not prefer relative imports in @InjectableInit
## [1.0.0+1]
- Fix some analysis warnings for pub points
## [1.0.0] Breaking Change
- Add support for multi environments (annotation & inlined)
- Add generation-time check for duplicate dependencies under the same environment
- Fix 3rd party imports from src instead of library file issue
- Change generated file extension to .config.dart
- Change generated file applies to most of effective dart rules including preferring relative imports
- Clean up some code

## [0.4.0+1] 
- Update README file
- Add some comments
## [0.4.0] Breaking Changes!
- Change Methods inside of register modules are treated as factory methods now,
  so all params are considered injected params unless annotated with @factoryParam.
- Change registerModule is now replaced with @module
- Change RegisterAs(Type) Annotation is now replaced with @Injectable(as:Type)
- Change Singleton.Lazy() is replaced with @LazySingleton()
- Add generateForDir property to @InjectableInt to specify what directories to generate for.
- Fix imports issue when working with bin directory

 
## [0.3.0] Breaking Changes!
- add support for GetIt 4.0.0
- fix generic types are registered as dynamic
- fix unresolved future when registering asynchronous dependencies
- change asynchronous dependencies will be registered using async factory unless annotated with @preResolve

## [0.2.3]
- improve support for custom initializers
- fix src import issue

## [0.2.2]
- remove flutter dependency
- add support for custom initializers in register Modules
- minor fixes

## [0.2.1]

- fix typo in @Environment annotation

## [0.2.0] Breaking Changes!

- You now need to pass in your getIt instance to @initGetIt() func
- Rename @Bind to @RegisterAs to avoid confusion because,
  now we're annotating the implementation not the abstract.
- Add @factoryMethod annotation to mark named factories and static create methods.
- Add @registerModule annotation to support registering third party types.
- Fix eager singletons are registered before their dependencies.

## [0.1.0]

- initial release
