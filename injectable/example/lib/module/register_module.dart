import 'dart:async';

import 'package:example/services/abstract_service.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @prod
  @LazySingleton(as: Repo, dispose: disposeRepo)
  RepoImpl get repo;

  @dev
  Future<Repo> getRepo(LazyService service) {
    return Repo.asyncRepo(service);
  }

  @Named("StringsList")
  List get strings => ['strings'];
}

FutureOr disposeRepo(Repo instance) {
  instance.dispose();
}

abstract class Repo {
  @factoryMethod
  static Future<RepoImpl> asyncRepo(LazyService service) async {
    await Future.delayed(Duration(seconds: 1));
    return RepoImpl(service);
  }

  void dispose();
}

class RepoImpl extends Repo {
  final LazyService service;

  RepoImpl(this.service);

  @override
  void dispose() {
    print("Disposing RepoImpl");
  }
}
