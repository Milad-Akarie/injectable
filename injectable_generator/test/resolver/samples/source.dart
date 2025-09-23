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
