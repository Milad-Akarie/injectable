import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:injectable_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

class InjectableGenerator implements Generator {
  RegExp? _classNameMatcher, _fileNameMatcher;
  late bool _autoRegister;

  InjectableGenerator(Map options) {
    _autoRegister = options['auto_register'] ?? false;
    if (_autoRegister) {
      if (options['class_name_pattern'] != null) {
        _classNameMatcher = RegExp(options['class_name_pattern']);
      }
      if (options['file_name_pattern'] != null) {
        _fileNameMatcher = RegExp(options['file_name_pattern']);
      }
    }
  }

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final allDepsInStep = await generateDependenciesJson(
      library: library,
      libs: await buildStep.resolver.libraries.toList(),
      autoRegister: _autoRegister,
      classNameMatcher: _classNameMatcher,
      fileNameMatcher: _fileNameMatcher,
    );

    return allDepsInStep.isNotEmpty ? jsonEncode(allDepsInStep) : null;
  }
}
