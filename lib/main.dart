import 'package:material_ui/material_ui.dart';

import 'app_dependencies.dart';
import 'app.dart';

void main() async {
  await AppDependencies.initialize();
  runApp(const App());
}
