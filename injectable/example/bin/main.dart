import 'package:example/injector/injector.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

GetIt getIt = GetIt.instance;

void main() async {
  await getIt.init(environment: Environment.dev);

}
