import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart' show DartFormatter;
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'injectable_config_generator.dart';
import 'injectable_generator.dart';

var outputDeleted = false;

Builder injectableBuilder(BuilderOptions options) {
  return InjectableBuilder(options.config);
}

Builder injectableConfigBuilder(BuilderOptions options) {
  return InjectableConfigBuilder(options.config);
}

class InjectableBuilder extends Builder {
  final injectableGenerator;
  static const _outputExt = '.injectable.json';

  InjectableBuilder(Map<String, dynamic> options) : injectableGenerator = InjectableGenerator(options);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final lib = await buildStep.inputLibrary;
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    var generated = await injectableGenerator.generate(LibraryReader(lib), buildStep);
    if (generated != null) {
      var outputId = buildStep.inputId.changeExtension(_outputExt);
      if (!outputDeleted) {
        Glob("**.config.dart").listSync().forEach((file) => file.delete());
        outputDeleted = true;
      }
      await buildStep.writeAsString(outputId, generated);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [_outputExt],
      };
}

class InjectableConfigBuilder implements Builder {
  final Map outputs;
  final bool preferRelativeImports;
  final _formatter = DartFormatter();

  InjectableConfigBuilder(Map config)
      : preferRelativeImports = config['prefer_relative_imports'] ?? true,
        assert(config['outputs'] != null),
        outputs = config['outputs'];

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      r'$package$': outputs.keys.map((e) => "$e.config.dart").toList(),
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    outputDeleted = false;
    for (var outputEntry in outputs.entries) {
      var schema = outputEntry.key.startsWith("lib/") ? "package" : "asset";
      var uri = Uri(scheme: schema, path: "${outputEntry.key}.config.dart");

      Uri targetFile;
      var package = buildStep.inputId.package;
      if (uri.scheme == "package") {
        targetFile = uri.replace(path: uri.path.replaceFirst("lib", package));
      } else {
        targetFile = uri.replace(pathSegments: [package, ...uri.pathSegments]);
      }

      var generateForDir = <String>{};
      generateForDir.add(uri.pathSegments.first);
      var include = outputEntry.value != null ? outputEntry.value['include_inputs_from'] : null;
      if (include != null) {
        generateForDir.addAll((include.cast<String>()));
      }

      final dirPattern = generateForDir.length > 1 ? '{${generateForDir.join(',')}}' : '${generateForDir.first}';

      var generatedContent = await InjectableConfigGenerator().generate(
        Glob("$dirPattern/**.injectable.json"),
        buildStep,
        targetFile,
        preferRelativeImports: preferRelativeImports,
      );
      await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, uri.path),
        _formatter.format(generatedContent, uri: targetFile),
      );
    }
  }
}
