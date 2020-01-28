import 'package:injectable/injectable.dart';

@Bind.toNamedtype(ServiceImpl1)
@Bind.toNamedtype(ServiceImpl2)
abstract class Service {}

class ServiceImpl1 extends Service {}

class ServiceImpl2 implements Service {
  ServiceImpl2();
}

@injectable
class MyRepository {
  MyRepository(@Named.from(ServiceImpl1) Service service);
}
