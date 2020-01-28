import 'package:injectable/injectable_annotations.dart';

@Bind.toType(ServiceA, env: 'dev')
@Bind.toType(ServiceB, env: 'prod')
@injectable
abstract class Service {}

// @injectable
class ServiceA extends Service {}

class ServiceB extends Service {}

// @injectable
// class ServiceDDD {}
