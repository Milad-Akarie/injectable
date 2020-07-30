import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/importable_type_resolver.dart';

void main(List<String> arguments) {
//  configInjector();
  var importableTypes = [
    ImportableType(name: 'Client', import: 'package:services/client_1.dart'),
    ImportableType(name: 'Client', import: 'package:services/client_2.dart'),
    ImportableType(name: 'Client3Service', import: 'package:services/client_3.dart'),
    ImportableType(name: 'Client', import: 'package:services/client_3.dart'),
    ImportableType(name: 'ClientX', import: 'package:services/client_3.dart'),
    ImportableType(name: 'Client2Service', import: 'package:services/client_2.dart'),
  ];

  print(ImportableTypeResolver.resolvePrefixes(importableTypes.toSet()).map((e) => "${e.identity} as  ${e.prefix}").join("\n"));
}
