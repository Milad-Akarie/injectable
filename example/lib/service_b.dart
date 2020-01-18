import 'package:example/service_a.dart';
import 'package:example/service_c.dart';
import 'package:example/service_d.dart';
import 'package:injectable/injectable_annotations.dart';

@injectable
class SerivceB {
  final ServiceA serviceA;
  final SerivceC serivceC;
  final ServiceD serviceD;

  SerivceB(this.serviceA, this.serivceC, this.serviceD);
}
