// import 'package:injectable/injectable.dart';

// @injectable
// abstract class Service {
//   @factoryMethod
//   static create(Service11 s11) => ServiceImpl2();
// }

// @named
// @RegisterAs(Service, env: 'test')
// @injectable
// class ServiceImpl2 implements Service {
//   ServiceImpl2();
// }

// @injectable
// @RegisterAs(Service, env: 'dev')
// class ServiceImpl extends Service {}

// @injectable
// @dev
// class MyRepository {
//   @factoryMethod
//   MyRepository.from(Service ss);
// }

// @injectable
// class ServiceA {}

// @injectable
// class ServiceB {
//   ServiceB(ServiceA sa);
// }

// @injectable
// class Service3 {
//   Service3(Service2 s2s);
// }
import 'package:injectable/injectable.dart';

class Service2 {
  Service2(Service11 s1);
}

class Service11 {}
