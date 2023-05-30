import 'package:injectable/injectable.dart';

@injectable
class SimpleFactory {}

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
      @factoryParam SimpleFactory? simpleFactory);
}

@injectable
class AsyncFactoryWithNullableDeps {
  const AsyncFactoryWithNullableDeps(SimpleFactory? simpleFactory);
  @factoryMethod
  static Future<AsyncFactoryWithNullableDeps> create(
      @factoryParam SimpleFactory? simpleFactory) async {
    return AsyncFactoryWithNullableDeps(simpleFactory);
  }
}

class AsyncFactoryWithNonNullableDeps {
  const AsyncFactoryWithNonNullableDeps(SimpleFactory simpleFactory);
  @factoryMethod
  static Future<AsyncFactoryWithNonNullableDeps> create(
      @factoryParam SimpleFactory simpleFactory) async {
    return AsyncFactoryWithNonNullableDeps(simpleFactory);
  }
}

abstract class IFactory {}

@Injectable(as: IFactory)
class FactoryAsAbstract extends IFactory {}

@Injectable()
class ConstService{
  const ConstService();
}

@Injectable()
class ConstServiceWithDeps{
  const ConstServiceWithDeps(SimpleFactory simpleFactory);
}
