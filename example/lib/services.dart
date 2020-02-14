import 'package:injectable/injectable.dart';

@injectable
abstract class Service {
  @factoryMethod
  static create(Service11 s11) => ServiceImpl2();
}

@named
@RegisterAs(Service)
@singleton
class ServiceImpl2 implements Service {
  ServiceImpl2();
}

@prod
@RegisterAs(Service)
@singleton
class ServiceImpl extends Service {}

@injectable
class MyRepository {
  @factoryMethod
  MyRepository.from(Service ss);
}

@injectable
class ServiceA {}

@injectable
class ServiceB {
  ServiceB(ServiceA sa);
}

@injectable
class Service3 {
  Service3(Service2 s2);
}

@injectable
class Service2 {
  Service2(Service11 s1, ServiceA sa);
}

@injectable
class Service11 {}
