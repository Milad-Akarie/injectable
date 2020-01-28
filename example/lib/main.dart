import 'package:example/service_b.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable_annotations.dart';

import 'injector.dart';

void main() {
  configure();
  runApp(MyApp(null));
}

class MyApp extends StatelessWidget {
  MyApp(Service service);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        color: Colors.red,
      ),
    );
  }
}
