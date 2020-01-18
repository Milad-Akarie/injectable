class Injectable {
  final type;

  const Injectable([this.type]);

  const Injectable.single({this.type});

  const Injectable.factory({this.type});
}

const Injectable injectable = const Injectable.factory();

class Injecater {
  const Injecater();
}
