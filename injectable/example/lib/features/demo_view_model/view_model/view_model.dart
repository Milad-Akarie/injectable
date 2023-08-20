import 'package:injectable/fmvvm.dart';
import 'package:injectable/injectable.dart';

@lazySingletonViewModel
class DemoViewModel extends ANavigableViewModel {
  String _text = '';
  String get text => _text;
  set text(String text) {
    _text = text;
    notifyListeners();
  }

  DemoViewModel();
}
