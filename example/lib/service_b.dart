import 'package:example/service_c.dart';
import 'package:example/service_d.dart';

import 'package:injectable/injectable_annotations.dart';

abstract class AbstractClass {}

@Factory(bindTo: AbstractClass, instanceName: 'Mock')
class AbstractClassImpl implements AbstractClass {
  AbstractClassImpl(
      // SerivceC serviceC,
      // ServiceD servictDD,
      // SerivceC serivcecCc,
      );
}

@Factory(bindTo: AbstractClass, instanceName: 'Mock2')
class AbstractClassImpl2 implements AbstractClass {
  AbstractClassImpl2(
      // SerivceC serviceC,
      // ServiceD servictDD,
      // SerivceC serivcecCc,
      );
}

@Factory(resolovers: {AbstractClass: 'Mock'})
class MyBloc {
  @InstanceName('sdflksdf')
  final AbstractClass clazz;

  MyBloc(this.clazz);
}
