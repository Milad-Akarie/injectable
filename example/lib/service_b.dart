import 'package:injectable/injectable_annotations.dart';

abstract class Service {}

@Injectable(bindTo: Service)
class ServiceImpl1 implements Service {
  ServiceImpl1();
}

@development
// @Injectable(bindTo: Service)
class ServiceImpl2 implements Service {
  ServiceImpl2();
}

@production
// @injectable
class MyRepository {
  MyRepository(
      // @InstanceName('impl1') Serviceimpl,
      // ServiceImpl1 impl1,
      // ServiceImpl2 impl2,
      );
}
