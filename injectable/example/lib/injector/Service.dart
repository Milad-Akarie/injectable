import 'package:injectable/injectable.dart';

abstract class Service {
  Set<String> get environments;
}

@injectable
class NamedConstructor {
  @factoryMethod
  NamedConstructor.fromService(Service service);
}

@injectable
class AsyncFactoryInstance {
  @factoryMethod
  static Future<AsyncFactoryInstance> init() {
    return Future.value(AsyncFactoryInstance());
  }
}

@dev
@preResolve
@singleton
class AsyncLazySingletonInstance {
  @factoryMethod
  static Future<AsyncLazySingletonInstance> init() {
    return Future.value(AsyncLazySingletonInstance());
  }
}
