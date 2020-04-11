import 'package:injectable/injectable.dart';

@registerModule
abstract class RegisterModule {
  // AbsService get absS;
  // Future<ServiceX> genIml(String x, int y) async => ServiceX();
  // @singleton
  // ServiceX ser();
  // @singleton
  // TestClass get testClass;
  // TestSingleton2 get testSing33;

  // TestSingleton testSing(String x, int y) => TestSingleton();

  // BackendService getService(String url) => BackendService(url);
  // @preResolve
  // @Singleton(dependsOn: [TestClass])
  // Future<TestSingleton> get futureSing => TestSingleton.create();

  // TestSingleton2 get test;
  @preResolve
  Future<ApiClient> get apiClient => ApiClient.create();

  @preResolve
  Future<ApiClient> get apiClient2 => ApiClient.create();
}

// // @Named("class")
// // @injectable
// class TestSingleton2 {
//   TestSingleton2(AbsService service);
// }

// abstract class AbsService<T> {}

@injectable
class BackendService {}

// @RegisterAs(BackendService, env: 'test')
// @injectable
// class BackendServiceMock extends Mock implements BackendService {}

// @injectable
class ApiClient {
  @factoryMethod
  static Future<ApiClient> create() async {
    return ApiClient();
  }
}
