// ignore_for_file: public_member_api_docs

import 'package:injectable/injectable.dart';


@module
abstract class RegisterModule {
  @dev
  @Injectable(as: Client)
  ApiClient client(Service service) {
    return ApiClient(service);
  }

  String get baseUrl => "String";
}

class ApiClient extends Client {
  ApiClient(Service service);
}

@injectable
class Service {}

abstract class Client {}