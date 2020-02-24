import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@registerModule
abstract class RegisterModule {
  // @dev
  @singleton
  Dio get dioDev => Dio(BaseOptions(baseUrl: "basweUwrl"));

  @RegisterAs(ServiceAbs)
  ServiceAA get serviceAA;

  @dev
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

class ServiceAA implements ServiceAbs {
  ServiceAA(FirebaseAuth auth, Dio dio);
}

abstract class ServiceAbs {}
