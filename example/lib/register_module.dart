import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  // @Singleton(as: LocalStorage)
  LocalStorage apiClient(
    @factoryParam String url,
    LocalStorage localStorage,
    @factoryParam int x,
  ) =>
      ApiClient.named(url);

  // @singleton
  // ApiClient api(String x) => ApiClient.named(x);
}

// @singleton
// @RegisterAs(LocalStorage)
// @test
@Injectable(as: LocalStorage)
class ApiClient extends LocalStorage {
  @factoryMethod
  ApiClient.named(String url);
}

abstract class LocalStorage {}
