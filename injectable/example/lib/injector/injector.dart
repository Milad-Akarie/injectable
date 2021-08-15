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

@Injectable()
class ServiceB {
  ServiceB(ServiceA serviceA);
}
