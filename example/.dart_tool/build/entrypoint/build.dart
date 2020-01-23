// ignore_for_file: directives_ordering

import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:source_gen/builder.dart' as _i2;
import 'package:injectable_generator/builder.dart' as _i3;
import 'package:build_config/build_config.dart' as _i4;
import 'dart:isolate' as _i5;
import 'package:build_runner/build_runner.dart' as _i6;
import 'dart:io' as _i7;

final _builders = <_i1.BuilderApplication>[
  _i1.apply('source_gen:combining_builder', [_i2.combiningBuilder],
      _i1.toNoneByDefault(),
      hideOutput: false, appliesBuilders: ['source_gen:part_cleanup']),
  _i1.apply('injectable_generator:injectable_builder', [_i3.injectableBuilder],
      _i1.toDependentsOf('injectable_generator'),
      hideOutput: true,
      appliesBuilders: ['injectable_generator:injector_file_remover']),
  _i1.apply('injectable_generator:injector_builder', [_i3.injectorBuilder],
      _i1.toDependentsOf('injectable_generator'),
      hideOutput: false),
  _i1.applyPostProcess('source_gen:part_cleanup', _i2.partCleanup,
      defaultGenerateFor: const _i4.InputSet())
];
main(List<String> args, [_i5.SendPort sendPort]) async {
  var result = await _i6.run(args, _builders);
  sendPort?.send(result);
  _i7.exitCode = result;
}
