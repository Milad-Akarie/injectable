// ignore_for_file: public_member_api_docs

import 'package:example/injector/Service.dart';
import 'package:example/injector/Service_impl.dart';
import 'package:example/injector/injector.dart';
import 'package:injectable/injectable.dart';

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
    await Future.delayed(Duration(seconds: 2));
    return WebService(null);
  }
}
