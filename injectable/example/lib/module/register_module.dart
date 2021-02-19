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

  @preResolve
  Future<int> get asyncValue => RepoImpl.asyncValue;

  @prod
  Future<Service> resolvedService(@factoryParam String param) => RepoImpl.asyncService;

  @dev
  RepoImpl baseRepo(@factoryParam String param) => RepoImpl.from(null);

  @platformMobile
  RepoImpl baseRepoWithParam(Service service) => RepoImpl.from(service);
}

abstract class Repo {}

class RepoImpl extends Repo {
  @factoryMethod
  RepoImpl.from(Service service);

  static Future<int> get asyncValue async {
    await Future.delayed(Duration(seconds: 2));
    return 10;
  }

  static Future<Service> get asyncService async {
    await Future.delayed(Duration(seconds: 1));
    return WebService(null);
  }
}
