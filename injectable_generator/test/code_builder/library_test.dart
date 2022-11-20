import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:test/test.dart';

void main() {
  group('Library test group', () {
    test("Simple init function", () {
      expect(generate([DependencyConfig.factory('Demo')]), '''
/// ignore_for_file: unnecessary_lambdas
/// ignore_for_file: lines_longer_than_80_chars
/// initializes the registration of main-scope dependencies inside of [GetIt]
GetIt init(GetIt getIt,
    {String environment, EnvironmentFilter environmentFilter}) {
  final gh = GetItHelper(getIt, environment, environmentFilter);
  gh.factory<Demo>(() => Demo());
  return getIt;
}
''');
    });
    test("Simple init function with one register statement", () {
      expect(generate([DependencyConfig.factory('Demo')]), '''
/// ignore_for_file: unnecessary_lambdas
/// ignore_for_file: lines_longer_than_80_chars
/// initializes the registration of main-scope dependencies inside of [GetIt]
GetIt init(GetIt getIt,
    {String environment, EnvironmentFilter environmentFilter}) {
  final gh = GetItHelper(getIt, environment, environmentFilter);
  gh.factory<Demo>(() => Demo());
  return getIt;
}
''');
    });

    test("Simple asExtension init", () {
      expect(generate([DependencyConfig.factory('Demo')], asExt: true), '''
/// ignore_for_file: unnecessary_lambdas
/// ignore_for_file: lines_longer_than_80_chars
extension GetItInjectableX on GetIt {
  /// initializes the registration of main-scope dependencies inside of [GetIt]
  GetIt init({String environment, EnvironmentFilter environmentFilter}) {
    final gh = GetItHelper(this, environment, environmentFilter);
    gh.factory<Demo>(() => Demo());
    return this;
  }
}
''');
    });
  });
}

String generate(List<DependencyConfig> input, {bool asExt = false}) {
  final library = LibraryGenerator(
    dependencies: input,
    initializerName: 'init',
    asExtension: asExt,
  ).generate();
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  return DartFormatter().format(library.accept(emitter).toString());
}
