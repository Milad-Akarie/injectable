import 'package:injectable/injectable.dart';

import 'private_named_super_base.dart';

export 'private_named_super_base.dart';

@injectable
class PrivateNamedSuperChild extends PrivateNamedSuperBase<int> {
  const PrivateNamedSuperChild({required super.dependency})
    : super(extraName: 'x');
}

@injectable
class PrivateNamedSuperGrandchild extends PrivateNamedSuperMid<int> {
  const PrivateNamedSuperGrandchild({required super.dependency});
}
