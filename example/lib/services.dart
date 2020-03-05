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

// @singleton
// class ComponentBloc {
//   ComponentBloc(
//     ProductService s1,
//     CategoriesService s2,
//   );
// }

// @injectable
// class ProductService {
//   @factoryMethod
//   static ProductService create(
//     @factoryParam String varName,
//     @factoryParam int varTwo,
//   ) =>
//       ProductService();
// }

// @injectable
// class CategoriesService {}

// @dev
// @singleton
// class TestClass {
//   TestClass();
//   // @factoryMethod
//   static Future<TestClass> create() async => TestClass();
// }

// @prod
// @Singleton(dependsOn: [TestClass])
// class TestSingleton {
//   TestSingleton();
//   @factoryMethod
//   static Future<TestSingleton> create(TestClass claxx) async => TestSingleton();
// }
