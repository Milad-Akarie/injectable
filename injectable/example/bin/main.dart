import 'package:example/injector/injector.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

GetIt getIt = GetIt.instance;

void main() async {
  await configInjector(getIt, env: Environment.prod);


}
