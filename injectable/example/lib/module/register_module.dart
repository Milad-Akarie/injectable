import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

@module
abstract class RegisterModule {
  // @prod
  // @LazySingleton(as: Repo)
  // RepoImpl get repo;
  //
  // @dev
  // Future<Repo> getRepo(LazyService service) {
  //   return Repo.asyncRepo(service);
  // }
  //
  // List get strings => ['strings'];
}

// abstract class Repo {
//   @factoryMethod
//   static Future<RepoImpl> asyncRepo(LazyService service) async {
//     await Future.delayed(Duration(seconds: 1));
//     return RepoImpl(service);
//   }
//
//   void dispose();
// }
//
// class RepoImpl extends Repo {
//   final LazyService service;
//
//   RepoImpl(this.service);
//
//   @overrid
//   void dispose() {
//     // TODO: imxplement dispose
//   }
// }

abstract class AbsService {
  FutureOr dispose();
}

@Singleton(as: AbsService, dispose: Disposable.dispose)
class DisposableService extends AbsService {
  // @disposeMethod
  @override
  FutureOr dispose() {}
}

class Disposable {
  static FutureOr dispose(AbsService repo) {}
}

FutureOr dispose(AbsService repo, String name) {}
