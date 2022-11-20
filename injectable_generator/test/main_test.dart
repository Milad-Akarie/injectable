import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

void main() {
  final library = Library(
    (b) => b
      ..body.addAll(
        [
          Extension(
            (b) => b
              ..name = 'GetItInjectableX'
              ..on = refer('GetIt')
              ..methods.add(Method(
                (b) => b
                  ..returns = refer('Future')
                  ..name = 'init'
                  ..modifier = MethodModifier.async
                  ..body = Block(
                    (b) => b.statements.addAll([
                      refer('gh').property('factory').call([
                        Method(
                          (b) => b
                            ..lambda = true
                            ..body = refer('Service').newInstance([
                              refer('get').call([], {}, [refer('Service')])
                            ]).code,
                        ).closure
                      ], {}, [
                        refer('Service')
                      ]).statement
                    ]),
                  ),
              )),
          )
        ],
      ),
  );

  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  print(DartFormatter().format(library.accept(emitter).toString()));
}
