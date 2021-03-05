import 'package:example/injector/injector.dart';
import 'package:injectable/injectable.dart';

//
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
@preResolve
@Injectable(as: AbstractService)
class AsyncService extends AbstractService {
  @override
  final Set<String> environments;

  AsyncService(
    @Named(kEnvironmentsName) this.environments,
  );

  @factoryMethod
  static Future<AsyncService> create(
    @Named(kEnvironmentsName) Set<String> envs,
  ) =>
      Future.value(AsyncService(envs));
}

abstract class IService {}

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
