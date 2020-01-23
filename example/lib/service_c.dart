import 'package:flutter/foundation.dart';
import 'package:injectable/injectable_annotations.dart';

@Factory()
class SerivceC {
  SerivceC();

  SerivceC.fromJson(@InstanceName('sdf') SerivceC serivcess);
}
