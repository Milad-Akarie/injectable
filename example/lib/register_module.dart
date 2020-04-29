import 'package:example/user.dart';
import 'package:injectable/injectable.dart';
import 'package:i18n_extension/default.i18n.dart';

import 'generic.dart';

@registerModule
abstract class RegisterModule {
  // AbsService get absS;
  // Future<ServiceX> genIml(String x, int y) async => ServiceX();
  // @singleton
  // ServiceX ser();
  // @singleton
  // TestClass get testClass;
  // TestSingleton2 get testSing33;

  BackendService testSing(User<Generic> x, int y) =>
      BackendService("Title".i18n);

  // BackendService getService(String url) => BackendService(url);
  // @preResolve
  // @Singleton(dependsOn: [TestClass])
  // Future<TestSingleton> get futureSing => TestSingleton.create();

  // TestSingleton2 get test;
  @preResolve
  Future<ApiClient> get apiClient => ApiClient.create();
}

// // @Named("class")
// // @injectable
// class TestSingleton2 {
//   TestSingleton2(AbsService service);
// }

// abstract class AbsService<T> {}

// @injectable
class BackendService {
  final String title;

  BackendService(this.title);
}

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
