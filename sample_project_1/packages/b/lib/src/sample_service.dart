import 'package:injectable/injectable.dart';

@singleton
class SampleService {
  SampleService();
}

@singleton
class InterfaceConsumingClass {
  InterfaceConsumingClass(DataServiceInterface dataServiceInterface);
}

abstract interface class DataServiceInterface {}
