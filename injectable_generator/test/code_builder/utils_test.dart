import 'package:injectable_generator/code_builder/builder_utils.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:injectable_generator/models/importable_type.dart';
import 'package:injectable_generator/models/injected_dependency.dart';

main() {
  var typeX = ImportableType(name: 'TypeX');
  var typeB = ImportableType(name: 'TypeB');
  var typeC = ImportableType(name: 'TypeC');
  // var typeANamed = ImportableType(name: 'TypeA');
  final unSortedDeps = [
    DependencyConfig(
      type: typeC,
      typeImpl: typeC,
      dependencies: [
        InjectedDependency(
          type: typeB,
          paramName: 'typeB',
          isFactoryParam: false,
          isPositional: false,
        )
      ],
    ),
    DependencyConfig(type: typeX, typeImpl: typeX),
    DependencyConfig(
      type: typeB,
      typeImpl: typeB,
      dependencies: [
        InjectedDependency(
          type: typeX,
          instanceName: 'named',
          paramName: 'typeX',
          isFactoryParam: false,
          isPositional: false,
        )
      ],
    ),
    DependencyConfig(type: typeX, typeImpl: typeX, instanceName: 'named'),
  ];

  var sorted = sortDependencies(unSortedDeps);
  print(sorted.map((e) => '${e.type}#${e.instanceName}'));
  // expect(
  //   [typeA, typeB, typeC],
  //   equals(
  //     sorted.map((e) => e.type).toList(),
  //   ),
  // );
}
