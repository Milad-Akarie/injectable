import 'package:example/injector/Service.dart';
import 'package:injectable/injectable.dart';

import 'injector.dart';

@platformMobile
@Injectable(as: AbstractService)
class MobileService extends AbstractService {
  @override
  final Set<String> environments;

  MobileService(@Named(kEnvironmentsName) this.environments) {}
}

@platformWeb
@LazySingleton(as: AbstractService)
class WebService extends AbstractService {
  @override
  final Set<String> environments;

  WebService(@Named(kEnvironmentsName) this.environments) {}
}

@dev
@preResolve
@Injectable(as: AbstractService)
class AsyncService extends AbstractService {
  @override
  final Set<String> environments;

  AsyncService(this.environments);

  @factoryMethod
  static Future<AsyncService> create(
    @Named(kEnvironmentsName) Set<String> envs,
  ) =>
      Future.value(AsyncService(envs));
}
