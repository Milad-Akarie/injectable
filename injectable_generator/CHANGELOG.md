# ChangeLog

## [0.3.2]

- fix registered abstract dependencies are reported missing.
- fix registering third party types as singleton throws an error.

## [0.3.1]

- fix resolve by instanceName is using positional var instead of named
- fix part files are imported as stand alone
- minor fixes

## [0.3.0] Breaking Changes!

- add support for GetIt 4.0.0
- fix generic types are registered as dynamic
- fix unresolved future when registering asynchronous dependencies
- change asynchronous dependencies will be registered using async factory unless annotated with @preResolve

## [0.2.4]

- fix type arguments are not imported.
- fix get with instanceName missing type.

## [0.2.3]

- improve support for custom initializers
- fix src import issue

## [0.2.2]

- remove flutter dependency
- add support for custom initializers in register Modules
- minor fixes

## [0.2.1]

- fix typo in @Environment annotation
- ignore abstract classes in auto mode.

## [0.2.0] Breaking Changes!

- You now need to pass in your getIt instance to @initGetIt() func
- Rename @Bind to @RegisterAs to avoid confusion because,
  now we're annotating the implementation not the abstract.
- Add @factoryMethod annotation to mark named factories and static create methods.
- Add @registerModule annotation to support registering third party types.
- Fix eager singletons are registered before their dependencies.

## [0.1.0]

- initial release
