import 'package:example/services/abstract_service.dart';
import 'package:injectable/injectable.dart';

import '../injector/injector.dart';

@module
abstract class RegisterModule {
  @prod
  @platformMobile
  @Injectable(as: Repo)
  RepoImpl get repo;

  @Named("Repo")
  @dev
  @preResolve
  Future<Repo> getRepo(LazyService service) {
    return Repo.asyncRepo(service);
  }
}

abstract class Repo {
  @factoryMethod
  static Future<RepoImpl> asyncRepo(LazyService service) async {
    await Future.delayed(Duration(seconds: 1));
    return RepoImpl(service);
  }
}

class RepoImpl extends Repo {
  final LazyService service;

  RepoImpl(this.service);
}
