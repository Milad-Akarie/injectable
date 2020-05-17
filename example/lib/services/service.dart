import 'package:injectable/injectable.dart';


@Injectable(as: Service)
class DemoService implements Service {
  @factoryMethod
  static Future<DemoService> init() async => DemoService();
}

abstract class Service {}
