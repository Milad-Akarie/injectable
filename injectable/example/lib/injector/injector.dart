import 'package:example/services/abstract_service.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

const platformMobile = Environment('platformMobile');
const platformWeb = Environment('platformWeb');

@InjectableInit(
  asExtension: true,
  initializerName: 'init',
  // ignoreUnregisteredTypes: [ServiceA],
)
configInjector(
  GetIt getIt, {
  String? env,
  EnvironmentFilter? environmentFilter,
}) {
  return getIt.init(
    environmentFilter: environmentFilter,
    environment: env,
  );
}

typedef IntFunction = int Function(int x);

@injectable
IntFunction intFunction = (i) => i + 1;

@Injectable()
class ServiceA {
  final IntFunction? dependency;
  final Function? dep2;

  ServiceA({
    @factoryParam this.dependency,
    @factoryParam this.dep2,
  });
}

@injectable
class AsyncServiceA {
  AsyncServiceA(AsyncService x);
}

@injectable
class World {
  @factoryMethod
  static Future<World> create() async => World();

  String get name => 'World';
}

@injectable
class Hello {
  final World _world;

  @factoryMethod
  static Future<Hello> create(World world) async => Hello(world);

  Hello(this._world);

  String greeting() => 'Hello ${_world.name}!';
}
