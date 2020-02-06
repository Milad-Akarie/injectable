import 'package:example/service.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.iconfig.dart';

final getIt = GetIt.instance;

@injectableInit
void configure() async => $initGetIt(getIt);

@RegisterModule
abstract class Module {
  @Bind(ServiceImpl2)
  Service get serviceImpl2;

  @Bind(ServiceImpl2)
  Service get serviceImpl22;

  Future<Service> get prefs => Future.value();
}
