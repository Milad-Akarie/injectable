import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@registerModule
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
  // AbsService get absS;
  // Future<ServiceX> genIml(String x, int y) async => ServiceX();
  // @singleton
  // ServiceX ser();
  // @singleton
  // TestClass get testClass;
  // TestSingleton2 get testSing33;

  // TestSingleton testSing(String x, int y) => TestSingleton();

  BackendService getService(String url) => BackendService(url);
  // @preResolve
  // @Singleton(dependsOn: [TestClass])
  // Future<TestSingleton> get futureSing => TestSingleton.create();
}

// @injectable
// class TestSingleton2 {
//   TestSingleton2(@factoryParam String x, TestSingleton test);
// }

abstract class AbsService<T> {}

class BackendService extends AbsService<int> {
  BackendService(@factoryParam String url);
}

@injectable
class ApiClient {
  @factoryMethod
  static Future<ApiClient> create() async {
    return ApiClient();
  }
}
