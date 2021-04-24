// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart';
import 'package:injectable_micropackages/injectable_micropackages.dart';

import '../sub/sub_test_service.dart';
import '../test_service.dart';

/// adds generated dependencies
/// to the provided [GetIt] instance

GetIt $initGetIt(
  GetIt get, {
  String environment,
  EnvironmentFilter environmentFilter,
}) {
  final gh = GetItHelper(get, environment, environmentFilter);
  gh.factory<SubTestService>(() => SubTestService(), instanceName: '', registerFor: null);
  gh.factory<TestService>(() => TestService(), registerFor: null, instanceName: '');
  return get;
}
