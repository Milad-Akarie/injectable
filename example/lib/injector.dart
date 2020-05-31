import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.iconfig.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => $initGetIt(getIt);

@module
abstract class RepositoryModule {
  @prod
  @dev
  @test
  @lazySingleton
  UserRepository get liveUserRepository => LiveUserRepository();

  @dev
  @lazySingleton
  UserRepository get fakeUserRepository => FakeUserRepository();
}

abstract class UserRepository {}

class LiveUserRepository implements UserRepository {}

class FakeUserRepository implements UserRepository {}
