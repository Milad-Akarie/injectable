// ignore_for_file: public_member_api_docs

import 'package:example/services/client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @dev
  @Injectable(as: Client)
  ApiClient client(Service service) {
    return ApiClient(service);
  }

  @dev
  @preResolve
  Future<Service> get service => Service.init();
}

class ApiClient extends Client {
  ApiClient(Service service);
}

class Service {
  static Future init() async => Service();
}

