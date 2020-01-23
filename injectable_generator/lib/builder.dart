import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'injectable_generator.dart';
import 'injector_generator.dart';

Builder injectableBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectableGenerator(),
    generatedExtension: '.injectable.json',
  );
}

Builder injectorBuilder(BuilderOptions options) {
  return LibraryBuilder(
    InjectorGenerator(),
    generatedExtension: '.gi.dart',
  );
}

PostProcessBuilder injectorFileRemover(BuilderOptions options) {
  return FileDeletingBuilder(['.gi.dart']);
}
