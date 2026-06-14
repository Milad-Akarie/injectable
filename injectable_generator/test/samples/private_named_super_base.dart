import 'package:injectable/injectable.dart';

@injectable
class PrivateNamedDep {
  const PrivateNamedDep();
}

class PrivateNamedSuperBase<T> {
  const PrivateNamedSuperBase({
    required this._dependency,
    required this._extraName,
  });

  // ignore: unused_field
  final PrivateNamedDep _dependency;
  // ignore: unused_field
  final String _extraName;
}

// Mid-level class that itself forwards a super-formal to the base. Exercises
// recursion in the resolver's super-formal type walk.
class PrivateNamedSuperMid<T> extends PrivateNamedSuperBase<T> {
  const PrivateNamedSuperMid({required super.dependency})
    : super(extraName: 'x');
}
