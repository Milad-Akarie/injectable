import 'package:injectable/injectable.dart';
import 'package:b/src/sample_service.dart';

@Singleton(as: DataServiceInterface)
class DataService implements DataServiceInterface {
  DataService(SampleService sampleService);
}
