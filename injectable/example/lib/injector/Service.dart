import 'package:example/module/register_module.dart';
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
@Singleton(dependsOn: [Service, String], signalsReady: false)
class AsyncLazySingletonInstance {
  @factoryMethod
  static Future<AsyncLazySingletonInstance> init() {
    return Future.value(AsyncLazySingletonInstance());
  }
}

@Injectable()
class SingletonInstance {
  SingletonInstance(Service service, @factoryParam String param);
  // @factoryMethod
  // static Future<AsyncLazySingletonInstance> init() {
  //   return Future.value(AsyncLazySingletonInstance());
  // }
}
