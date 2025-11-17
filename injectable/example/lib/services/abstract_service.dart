import 'package:example/injector/injector.dart';
import 'package:injectable/injectable.dart';

@Singleton()
class ConstService {
  const ConstService();
}

abstract class AbstractService {
  Set<String> get environments;
}

@platformMobile
@Injectable(as: AbstractService)
class MobileService extends AbstractService {
  @override
  final Set<String> environments;

  @factoryMethod
  MobileService.fromService(@Named(kEnvironmentsName) this.environments);
}

@named
@platformWeb
@LazySingleton(as: AbstractService)
class WebService extends AbstractService {
  @override
  final Set<String> environments;

  WebService(@Named(kEnvironmentsName) this.environments);
}

@dev
@Injectable(as: AbstractService)
class AsyncService extends AbstractService {
  @override
  final Set<String> environments;

  AsyncService(@Named(kEnvironmentsName) this.environments);

  @FactoryMethod(preResolve: true)
  static Future<AsyncService> create(
    @Named(kEnvironmentsName) Set<String> envs,
  ) => Future.value(AsyncService(envs));
}

abstract class IService {}

@named
@dev
@Injectable(as: IService)
class ServiceImpl extends IService {
  ServiceImpl(@factoryParam String? param);
}

@test
@Injectable(as: IService)
class LazyServiceImpl extends IService {
  LazyServiceImpl._(String? param);

  @factoryMethod
  static Future<IService> create(@factoryParam String? param) {
    return Future.value(LazyServiceImpl._(param));
  }
}

@singleton
class PostConstructableService {
  final IService service;

  PostConstructableService(@Named("ServiceImpl") this.service);

  @PostConstruct()
  Future<void> init() {
    return Future.value(null);
    // return this;
  }
}

sealed class Model {
  Model get m {
    return switch (this) {
      ModelX() => ModelX(),
      ModelY() => ModelY(),
    };
  }
}

@Injectable(as: Model)
class ModelX extends Model {}

class ModelY extends Model {}
