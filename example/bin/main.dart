import 'dart:convert';

import 'package:example/injector/injector.dart';
import 'package:example/services/register_module.dart';
import 'package:injectable/injectable.dart';

void main(List<String> arguments) {
//  configureDependencies(Environment.dev);

  var set = {'one', 'two'};

  print(set.lookup('one'));
}
