import 'package:flutter/material.dart';

import 'injector.app.dart';

void main() {
  Injector.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        color: Colors.red,
      ),
    );
  }
}
