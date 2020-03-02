import 'package:example/services.dart';
import 'package:injectable/injectable.dart';

@registerModule
abstract class RegisterModule {
  // @dev
  // @singleton
  // Dio get dioDev => Dio(BaseOptions(baseUrl: "basweUwrl"));

  // @RegisterAs(ServiceAbs)
  // ServiceAA get serviceAA;

  // @dev
  // Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  // Future<ServiceAA> get service => ServiceAA.createService();
  // @asInstance
  // @singleton
  // Future<ServiceAA<Service11>> get serviceA =>
  //     ServiceAA.createService<Service11>('');
  // // @dev
  // @singleton
  // ServiceX get serviceX;
}
// @injectable

// @singleton
class ServiceX {
  ServiceX(ServiceAA serviceAA);
}

// @asInstance
// @singleton
@singleton
class ServiceAA<T> {
  @factoryMethod
  static Future<ServiceAA> createService<T>(String x) async => ServiceAA<T>();
}
