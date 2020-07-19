import 'package:injectable/injectable.dart';

@Injectable(as: Service, env: ['dev'])
class DevService implements Service {
  @factoryMethod
  static Future<DevService> init(@factoryParam String x) async => DevService();
}

@preResolve
@Injectable(as: Service, env: ['prod'])
class ProdService implements Service {
  @factoryMethod
  static Future<ProdService> init() async => ProdService();
}

abstract class Service {}
