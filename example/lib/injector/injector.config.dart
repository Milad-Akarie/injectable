import 'package:example/services/class.dart';
import 'package:example/services/client.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/get_it_helper.dart';
import 'package:example/services/register_module.dart';
import 'package:example/services/simple_class.dart';

/// Environment names
const _dev = 'dev';

/// adds generated dependencies
/// to the provided [GetIt] instance

void $initGetIt(GetIt g, {String environment}) {
  final gh = GetItHelper(g, environment);
  final registerModule = _$RegisterModule();
  gh.factory<Clazz>(() => Clazz());
  gh.factory<Client<dynamic>>(() => registerModule.client(g<Service>()),
      registerFor: {_dev});
  gh.factory<String>(() => registerModule.baseUrl);
  gh.factory<SimpleClass>(() => SimpleClass(g<String>(), g<String>()));
  gh.factory<SimpleClass2>(() => SimpleClass2(g<String>(), g<String>()));
}

class _$RegisterModule extends RegisterModule {}
