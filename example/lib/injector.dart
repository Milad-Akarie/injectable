import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.iconfig.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => $initGetIt(getIt);


abstract class UserRepository {}

class LiveUserRepository implements UserRepository {}

class FakeUserRepository implements UserRepository {}
