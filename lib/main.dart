import 'package:flutter/material.dart';
import 'app_dependencies.dart';
import 'app.dart';

void main() async {
  await AppDependencies.initialize();
  runApp(const App());
}
