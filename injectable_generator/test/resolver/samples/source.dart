import 'package:injectable/injectable.dart';

@injectable
class SimpleFactory {}

@injectable
class FactoryWithDeps {
  const FactoryWithDeps(SimpleFactory simpleFactory);
}

abstract class IFactory {}

@Injectable(as: IFactory)
class FactoryAsAbstract extends IFactory {}
