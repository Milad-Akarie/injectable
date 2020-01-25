import 'package:injectable/injectable_annotations.dart';

@singleton
@injectable
class ServiceD {
  ServiceD(ServiceDD serviceDD);
}

@production
@injectable
class ServiceDD {
  ServiceDD(ServiceDDD serviceDxDD);
}

@injectable
class ServiceDDD {}
