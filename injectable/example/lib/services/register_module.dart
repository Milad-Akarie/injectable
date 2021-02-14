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
  @preResolve
  Future<Service> get resolvedService => RepoImpl.asyncService;
}

abstract class Repo {}

class RepoImpl extends Repo {
  RepoImpl(Service service);

  static Future<int> get asyncValue async {
    await Future.delayed(Duration(seconds: 2));
    return 10;
  }

  static Future<Service> get asyncService async {
    await Future.delayed(Duration(seconds: 1));
    return WebService(null);
  }
}
