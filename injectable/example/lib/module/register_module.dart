import 'package:injectable/injectable.dart';

import '../injector/Service.dart';
import '../injector/Service_impl.dart';
import '../injector/injector.dart';

@module
abstract class RegisterModule {
  @prod
  @platformMobile
  @Injectable(as: Repo)
  RepoImpl get repo;

  @prod
  Future<AbstractService> resolvedService(@factoryParam String param) => RepoImpl.asyncService;

  @dev
  RepoImpl baseRepo(@factoryParam String param) => RepoImpl.from(null);

  @platformMobile
  RepoImpl baseRepoWithParam(AbstractService service) => RepoImpl.from(service);
}

abstract class Repo {}

class RepoImpl extends Repo {
  @factoryMethod
  RepoImpl.from(AbstractService service);

  static Future<AbstractService> get asyncService async {
    await Future.delayed(Duration(seconds: 1));
    return WebService(null);
  }
}
