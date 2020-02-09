# Example

```dart

import 'package:injectable/injectable_annotations.dart';

abstract class Service {}

@RegisterAs(Service, env: 'dev')
@injectable
class ServiceImpl1 extends Service {}

@RegisterAs(Service, env: 'prod')
@injectable
class ServiceImpl2 implements Service {

}

@injectable
class MyRepository {
  MyRepository(@Named.from(ServiceImpl1) Service service);
}
```
