import 'package:injectable/injectable.dart';

@injectable
class SimpleFactory {}

@injectable
class FactoryWithoutAnnotation {
  FactoryWithoutAnnotation._internal();
  // not annotated with @factoryMethod in order to take fist available
  FactoryWithoutAnnotation.valid() : this._internal();
  FactoryWithoutAnnotation.second() : this._internal();
}

@injectable
class FactoryWithDeps {
  const FactoryWithDeps(SimpleFactory simpleFactory);
}

@injectable
class FactoryWithNullableDeps {
  const FactoryWithNullableDeps(SimpleFactory? simpleFactory);
}

@injectable
class FactoryWithFactoryParams {
  const FactoryWithFactoryParams(@factoryParam SimpleFactory simpleFactory);
}

@Injectable(order: 1)
class FactoryWithInlineOrder {
  const FactoryWithInlineOrder();
}

@Order(1)
@injectable
class FactoryWithAnnotationOrder {
  const FactoryWithAnnotationOrder();
}

@Injectable(scope: 'scope')
class FactoryWithInlineScope {
  const FactoryWithInlineScope();
}

@Scope('scope')
@injectable
class FactoryWithAnnotationScope {
  const FactoryWithAnnotationScope();
}

@injectable
class FactoryWithNullableFactoryParams {
  const FactoryWithNullableFactoryParams(
    @factoryParam SimpleFactory? simpleFactory,
  );
}

@injectable
class FactoryWithFactoryStaticConstructor {
  FactoryWithFactoryStaticConstructor._();

  @factoryMethod
  factory FactoryWithFactoryStaticConstructor.namedFactory() =>
      FactoryWithFactoryStaticConstructor._();
}

@injectable
class FactoryWithNamedConstructor {
  FactoryWithNamedConstructor._();

  @factoryMethod
  FactoryWithNamedConstructor.namedFactory() : this._();
}

@injectable
class AsyncFactoryWithNullableDeps {
  const AsyncFactoryWithNullableDeps(SimpleFactory? simpleFactory);

  @factoryMethod
  static Future<AsyncFactoryWithNullableDeps> create(
    @factoryParam SimpleFactory? simpleFactory,
  ) async {
    return AsyncFactoryWithNullableDeps(simpleFactory);
  }
}

class AsyncFactoryWithNonNullableDeps {
  const AsyncFactoryWithNonNullableDeps(SimpleFactory simpleFactory);

  @factoryMethod
  static Future<AsyncFactoryWithNonNullableDeps> create(
    @factoryParam SimpleFactory simpleFactory,
  ) async {
    return AsyncFactoryWithNonNullableDeps(simpleFactory);
  }
}

abstract class IFactory {}

@Injectable(as: IFactory)
class FactoryAsAbstract extends IFactory {}

@Injectable()
class ConstService {
  const ConstService();
}

@Injectable()
class ConstServiceWithDeps {
  const ConstServiceWithDeps(SimpleFactory simpleFactory);
}

@injectable
class FactoryWithIgnoredParam {
  const FactoryWithIgnoredParam(
    SimpleFactory simpleFactory, {
    @ignoreParam String? ignored,
  });
}

typedef NamedRecord = ({SimpleFactory x, int y});

@Injectable()
class NamedRecordFactory {
  const NamedRecordFactory(@factoryParam NamedRecord record);
}

typedef PositionalRecord = (SimpleFactory x, int y);

@Injectable()
class PositionalRecordFactory {
  const PositionalRecordFactory(@factoryParam PositionalRecord record);
}

@Injectable()
class InlineNamedRecord {
  const InlineNamedRecord(@factoryParam ({SimpleFactory x, int y}) record);
}

@Injectable()
class InlinePositionalRecord {
  const InlinePositionalRecord(@factoryParam (SimpleFactory x, int y) record);
}

// Singleton tests

@Singleton()
class SimpleSingleton {}

@Singleton(signalsReady: true)
class SingletonWithSignalsReady {}

@Singleton(dependsOn: [SimpleFactory])
class SingletonWithDependsOn {}

@Singleton(signalsReady: true, dependsOn: [SimpleFactory, SimpleSingleton])
class SingletonWithSignalsReadyAndDependsOn {}

@LazySingleton()
class SimpleLazySingleton {}

@LazySingleton()
class LazySingletonWithDeps {
  const LazySingletonWithDeps(SimpleFactory simpleFactory);
}

// Named instance tests

@Named('myName')
@injectable
class NamedFactory {}

@named
@injectable
class NamedFromTypeFactory {}

// Environment tests

@Environment('dev')
@injectable
class DevOnlyFactory {}

@Environment('dev')
@Environment('test')
@injectable
class DevAndTestFactory {}

@Injectable(env: ['dev', 'prod'])
class InlineEnvFactory {}

// PreResolve tests

@preResolve
@injectable
class PreResolveFactory {
  @factoryMethod
  static Future<PreResolveFactory> create() async {
    return PreResolveFactory._();
  }

  PreResolveFactory._();
}

@injectable
class FactoryMethodWithPreResolve {
  @FactoryMethod(preResolve: true)
  static Future<FactoryMethodWithPreResolve> create() async {
    return FactoryMethodWithPreResolve._();
  }

  FactoryMethodWithPreResolve._();
}

// PostConstruct tests

@injectable
class FactoryWithPostConstruct {
  @postConstruct
  void init() {}
}

@injectable
class FactoryWithAsyncPostConstruct {
  @postConstruct
  Future<void> init() async {}
}

@injectable
class FactoryWithPostConstructReturnsSelf {
  @postConstruct
  FactoryWithPostConstructReturnsSelf init() {
    return this;
  }
}

@injectable
class FactoryWithAsyncPostConstructReturnsSelf {
  @PostConstruct(preResolve: true)
  Future<FactoryWithAsyncPostConstructReturnsSelf> init() async {
    return this;
  }
}

// Cache tests

@Injectable(cache: true)
class CachedFactory {
  const CachedFactory();
}

// Multiple factory params

@injectable
class FactoryWithTwoFactoryParams {
  const FactoryWithTwoFactoryParams(
    @factoryParam SimpleFactory simpleFactory,
    @factoryParam int count,
  );
}

// Named dependencies

@injectable
class FactoryWithNamedDependency {
  const FactoryWithNamedDependency(
    @Named('myName') SimpleFactory simpleFactory,
  );
}

@injectable
class FactoryWithNamedTypeDependency {
  const FactoryWithNamedTypeDependency(
    @Named.from(SimpleFactory) SimpleFactory simpleFactory,
  );
}

// Optional parameters

@injectable
class FactoryWithOptionalParams {
  const FactoryWithOptionalParams(SimpleFactory simpleFactory, [int? optional]);
}

@injectable
class FactoryWithOptionalNamedParams {
  const FactoryWithOptionalNamedParams(
    SimpleFactory simpleFactory, {
    int? optional,
  });
}

// Dispose tests

@LazySingleton()
class LazySingletonWithDisposeMethod {
  const LazySingletonWithDisposeMethod();

  @disposeMethod
  void dispose() {}
}

@Singleton()
class SingletonWithDisposeMethod {
  const SingletonWithDisposeMethod();

  @disposeMethod
  Future<void> dispose() async {}
}

// Additional test cases for better coverage

@Injectable()
class FactoryWithGenericDeps {
  const FactoryWithGenericDeps(List<SimpleFactory> factories);
}

@Injectable()
class FactoryWithMapDeps {
  const FactoryWithMapDeps(Map<String, SimpleFactory> factoryMap);
}

@Injectable()
class FactoryWithRequiredNamedParams {
  const FactoryWithRequiredNamedParams({required SimpleFactory simpleFactory});
}

@Injectable()
class FactoryWithMixedParams {
  const FactoryWithMixedParams(
    SimpleFactory first,
    @factoryParam int count, {
    String? optional,
    required SimpleSingleton singleton,
  });
}

@Injectable(as: IFactory)
class MultipleInterfaces extends IFactory {
  MultipleInterfaces();
}

@LazySingleton()
class LazySingletonWithAsyncDispose {
  const LazySingletonWithAsyncDispose();

  @disposeMethod
  Future<void> dispose() async {}
}

typedef VoidCallback = void Function();

@Injectable()
class FactoryWithFunctionParam {
  const FactoryWithFunctionParam(VoidCallback callback);
}

@Injectable()
class FactoryWithComplexGeneric {
  const FactoryWithComplexGeneric(Map<String, List<SimpleFactory>> complexMap);
}

@Injectable()
class FactoryWithDefaultValue {
  const FactoryWithDefaultValue(SimpleFactory simpleFactory, {int count = 10});
}

@Singleton(dependsOn: [SimpleFactory, SimpleSingleton, SimpleLazySingleton])
class SingletonWithMultipleDependsOn {}

@Injectable(env: [])
class FactoryWithEmptyEnv {
  const FactoryWithEmptyEnv();
}

@Injectable()
class FactoryWithMultipleNamedParams {
  const FactoryWithMultipleNamedParams({
    SimpleFactory? first,
    SimpleSingleton? second,
    SimpleLazySingleton? third,
  });
}

@Injectable()
class FactoryWithBothPositionalAndNamed {
  const FactoryWithBothPositionalAndNamed(
    SimpleFactory positional, {
    SimpleSingleton? named,
  });
}

@Injectable()
class FactoryWithNullableGeneric {
  const FactoryWithNullableGeneric(List<SimpleFactory>? factories);
}

// Test for static class method as dispose function
class DisposeFunctions {
  static void disposeExternal(LazySingletonWithExternalDispose instance) {}
  static Future<void> disposeAsync(SimpleSingleton instance) async {}
}

@LazySingleton(dispose: DisposeFunctions.disposeExternal)
class LazySingletonWithExternalDispose {}

// Test for nested records in type arguments
typedef NestedRecord = ({String name, ({int x, int y}) position});

@Injectable()
class FactoryWithNestedRecord {
  const FactoryWithNestedRecord(@factoryParam NestedRecord record);
}

// Test for generic with record type argument
@Injectable()
class FactoryWithGenericRecordArg {
  const FactoryWithGenericRecordArg(List<({String id, int value})> items);
}

// Test for nullable record
@Injectable()
class FactoryWithNullableRecord {
  const FactoryWithNullableRecord(@factoryParam ({int x, int y})? point);
}
