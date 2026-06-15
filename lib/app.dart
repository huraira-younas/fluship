import 'package:flutter/material.dart';
import 'core/app_theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _themeNotifier = ThemeNotifier();

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _themeNotifier.themeData,
          home: const _HomePage(),
          title: 'Fluship',
        );
      },
    );
  }
}
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final flushipTheme = context.flushipTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fluship',
          style: TextStyle(color: flushipTheme.colors.text),
        ),
      ),
      body: Center(
        child: Text(
          'Theme: ${flushipTheme.theme.id.key}',
          style: TextStyle(color: flushipTheme.colors.accent, fontSize: 18),
        ),
      ),
    );
  }
}

