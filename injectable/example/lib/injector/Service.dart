import 'package:injectable/injectable.dart';

abstract class AbstractService {
  Set<String> get environments;
}

@injectable
class NamedConstructor {
  @factoryMethod
  NamedConstructor.fromService(AbstractService service);
}

@injectable
class AsyncFactoryInstance {
  @factoryMethod
  static Future<AsyncFactoryInstance> init() {
    return Future.value(AsyncFactoryInstance());
  }
}

@dev
@Singleton()
class AsyncLazySingletonInstance {
  @factoryMethod
  static Future<AsyncLazySingletonInstance> init() {
    return Future.value(AsyncLazySingletonInstance());
  }
}

@Singleton()
class SingletonInstance {
  SingletonInstance(AbstractService service);
}
