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
