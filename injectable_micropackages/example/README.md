# Example

```dart

import 'package:injectable/injectable_annotations.dart';

abstract class Service {}

@named
@prod
@Injectable(as: Service)
class ServiceImpl1 extends Service {}


@Injectable(as: Service, env: [Envirnoment.dev])
class ServiceImpl2 implements Service {}

@injectable
class MyRepository {
  MyRepository(@Named.from(ServiceImpl1) Service service);
}
```
