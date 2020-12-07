import 'package:example/injector/injector.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';

import 'Service.dart';

@platformMobile
@Injectable(as: Service)
class MobileService extends Service {
  @override
  final Set<String> environments;

  MobileService(@Named(kEnvironmentsName) this.environments) {}
}

@platformWeb
@Injectable(as: Service)
class WebService extends Service {
  @override
  final Set<String> environments;

  WebService(@Named(kEnvironmentsName) this.environments) {}
}
