import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'injector.iconfig.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configure() async => await $initGetIt(getIt);
