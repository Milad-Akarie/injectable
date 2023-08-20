import 'package:flutter/material.dart';

abstract class ANavigableViewModel extends ChangeNotifier {
  ANavigableViewModel();

  void onChange() {
    notifyListeners();
  }
}
