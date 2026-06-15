import 'package:fluship/core/responsive/responsive.dart';
import 'package:flutter/material.dart';

import 'features/pipeline/views/pipeline_screen.dart';
import 'core/app_theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _theme = ThemeNotifier();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _theme,
      builder: (context, _) {
        return OrientationLockScope(
          lock: .portrait,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const PipelineScreen(),
            theme: _theme.themeData,
            title: 'Fluship',
          ),
        );
      },
    );
  }
}
