import 'package:dio/dio.dart';
import 'package:example/injector.dart';
import 'package:flutter/material.dart';

void main() async {
  await configure();
  print(getIt<Dio>());
  // runApp(MaterialApp());
}
