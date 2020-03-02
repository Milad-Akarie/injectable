import 'package:dio/dio.dart';
import 'package:example/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@registerModule
abstract class RegisterModule {
  // @dev
  @singleton
  Dio get dioDev => Dio(BaseOptions(baseUrl: "basweUwrl"));

  // @RegisterAs(ServiceAbs)
  // ServiceAA get serviceAA;

  // @dev
  // Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  // Future<ServiceAA> get service => ServiceAA.createService();

  ServiceAA<Service11> get serviceA;
}

@injectable
class ServiceX {
  ServiceX(ServiceAA<Service11> serviceAA);
}

//@injectable
class ServiceAA<T> {
  @factoryMethod
  static ServiceAA createService<T>() => ServiceAA<T>();
}
