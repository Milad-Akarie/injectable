import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'injectable_app.dart';
import 'injectable_generator.dart';

Set<String> collected = Set();

Builder injectableBuilder(BuilderOptions options) {
  // gr stands for generated router.
  return LibraryBuilder(InjectableGenerator(), generatedExtension: '.injecatble.json');
}

Builder injectableAppBuilder(BuilderOptions options) {
  // gr stands for generated router.
  return LibraryBuilder(InjectableAppGenerator(), generatedExtension: '.app.dart');
}
