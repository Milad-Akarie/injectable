# ChangeLog
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
- Add option to customize the initilizer function name
- Add option to generate the initilizer function as an extension
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
