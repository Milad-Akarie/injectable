import 'package:injectable/injectable.dart';

@injectable
class SimpleFactory {}

@injectable
class AsyncFactory {}

@injectable
class FactoryWithDeps {
  const FactoryWithDeps(SimpleFactory simpleFactory);
}

@injectable
class FactoryWithNullableDeps {
  const FactoryWithNullableDeps(SimpleFactory? simpleFactory);
}

@injectable
class AsyncFactoryWithNullableDeps {
  const AsyncFactoryWithNullableDeps(AsyncFactory? asyncFactory);
  @factoryMethod
  static Future<AsyncFactoryWithNullableDeps> create(
      @factoryParam AsyncFactory? asyncFactory) async {
    return AsyncFactoryWithNullableDeps(asyncFactory);
  }
}

class AsyncFactoryWithNonNullableDeps {
  const AsyncFactoryWithNonNullableDeps(AsyncFactory asyncFactory);
  @factoryMethod
  static Future<AsyncFactoryWithNonNullableDeps> create(
      @factoryParam AsyncFactory asyncFactory) async {
    return AsyncFactoryWithNonNullableDeps(asyncFactory);
  }
}

abstract class IFactory {}

@Injectable(as: IFactory)
class FactoryAsAbstract extends IFactory {}
