import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  Client apiClient(
    @factoryParam String url,
  ) =>
      ApiClient(url);
}

@Injectable(as: Client)
class ApiClient extends Client {
  final String baseUrl;

  ApiClient(@Named('baseUrl') this.baseUrl);

  @override
  String get url => baseUrl;
}

abstract class Client {
  String get url;
}
