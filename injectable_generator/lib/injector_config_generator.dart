import 'dart:async';

import 'package:injectable/injectable_annotations.dart';
import 'package:injectable_generator/src/dependency_holder.dart';

class InjectorConfigGenerator {
  final List<DependencyHolder> clazzes;
  final String injectorName;

  InjectorConfigGenerator(this.clazzes, this.injectorName);

  FutureOr<String> generate() async {
    final buffer = StringBuffer();
    final imports =
        clazzes.fold<Set<String>>({}, (a, b) => a..addAll(b.imports));
    imports.where((i) => i != null).forEach((import) {
      buffer.writeln("import $import;");
    });

    buffer.writeln("import 'package:get_it/get_it.dart';");
    buffer.writeln("final GetIt getIt = GetIt.instance;");

    buffer.writeln("void \$$injectorName(){");

    clazzes.forEach((dep) {
      final constBuffer = StringBuffer();
      dep.dependencies.forEach((claName) {
        constBuffer.write("getIt<$claName>(),");
      });

      final typeArgs =
          dep.abstractClassName != null ? '<${dep.abstractClassName}>' : '';
      if (dep.type == InjectableTypes.factory) {
        buffer.writeln(
            "getIt.registerFactory$typeArgs(()=> ${dep.className}(${constBuffer.toString()})");
      } else if (dep.type == InjectableTypes.singleton) {
        buffer.writeln(
            "getIt.registerSingleton$typeArgs(${dep.className}(${constBuffer.toString()})");
      } else {
        buffer.writeln(
            "getIt.registerLazySingleton$typeArgs(()=> ${dep.className}(${constBuffer.toString()})");
      }

      if (dep.instanceName != null) {
        buffer.write(", instanceName: '${dep.instanceName}'");
      }
      if (dep.signalsReady != null) {
        buffer.write(', signalsReady: ${dep.signalsReady}');
      }
      buffer.write(");");
    });

    buffer.writeln("}");

    return buffer.toString();
  }
}
