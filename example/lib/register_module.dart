import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'injector.dart';

@registerModule
abstract class RegisterModule {
  @dev
  @singleton
  Dio get dioDev => Dio(BaseOptions(baseUrl: "baseUrl"));

  @prod
  ServiceAA get service;
  @dev
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

class ServiceAA {}
