import 'package:example/register_module.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.iconfig.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configure() async {
  $initGetIt(getIt);

  getIt.registerSingletonWithDependencies(() => ServiceAA(),
      dependsOn: [ServiceX]);

  // getIt.registerFactory(() => ServiceAA());
  // getIt.registerFactoryAsync(() => ServiceAA.createService());
  // getIt.registerSingletonAsync(() => ServiceAA.createService());
  // getIt.registerSingletonAsync(() => ServiceAA.createService());
  // getIt.registerSingletonWithDependencies(() => ServiceAA.createService());
  // getIt.registerLazySingletonAsync<SharedPreferences>(
  //     () async => SharedPreferences.getInstance());

  // getIt.registerFactoryParam<Dio, String, void>(
  //     (s, _) => Dio(BaseOptions(baseUrl: s)));
}
