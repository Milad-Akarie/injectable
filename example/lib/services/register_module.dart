import 'package:example/services/service.dart';
import 'package:injectable/injectable.dart';

// ignore_for_file: public_member_api_docs
@module
abstract class RegisterModule {
  @test
  @Injectable(as: Client)
  ApiClient get client;
}

@prod
@Singleton(as: Client)
class ApiClient extends Client {
  ApiClient(Service devService);

  @override
  String get url => 'Prod base url';
}

@Injectable(as: Client, env: [Environment.dev])
class ApiClientMock extends Client {
  @override
  String get url => 'Dev base url';
}

abstract class Client {
  String get url;
}
