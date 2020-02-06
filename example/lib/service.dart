import 'package:injectable/injectable.dart';

// // @production
// @Bind.toName('f')
// @Bind.toType(ServiceY)
// @injectable
abstract class Service {
  @factoryMethod
  static ServiceImpl2 create(ApiBloc bloc) => ServiceImpl2();
}

// @Bind.toAbstract(Service, env: Env.dev)
// @injectable
class ServiceImpl2 implements Service {
  ServiceImpl2();
}

// @injectable
@lazySingleton
class ApiBloc {
  ApiBloc(
    MyRepository repo,
  );

  @factoryMethod
  ApiBloc.fromX(ServiceImpl2 s2) {}
}

// @injectable
@dev
@singleton
class MyRepository {
  MyRepository(Service service);
}

// @injectable
// class ServiceA {}

// @injectable
// class ServiceB {
//   ServiceB(ServiceA sx);
// }

// @injectable
// class Service3 {
//   Service3(Service2 s1);
// }

// @injectable
// class Service2 {
//   Service2(Service1 s1, ServiceA sx);
// }

// @injectable
// class Service1 {}
