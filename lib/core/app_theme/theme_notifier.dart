import 'package:flutter/material.dart';

import 'registry/theme_preset_registry.dart';
import 'mappers/app_theme_data_mapper.dart';
import 'registry/app_theme_registry.dart';
import 'models/theme.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({String? initial}) {
    ThemePresetRegistry.registerAll();
    _active = AppThemeRegistry.get(initial ?? AppTheme.defaultThemeName);
  }

  late AppTheme _active;

  AppTheme get theme => _active;

  ThemePalette get colors => _active.palette;

  ThemeRadius get radius => _active.radius;

  ThemeSpacing get pad => _active.pad;

  ThemeData get themeData => _active.toThemeData();

  String get themeName => _active.name;

  void setTheme(String name) {
    if (_active.name == name) return;
    _active = AppThemeRegistry.get(name);
    notifyListeners();
  }
}
