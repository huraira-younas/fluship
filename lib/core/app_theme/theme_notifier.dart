import 'package:flutter/material.dart';

import 'registry/theme_preset_registry.dart';
import 'mappers/app_theme_data_mapper.dart';
import 'registry/app_theme_registry.dart';
import 'models/app_themes.dart';
import 'models/theme.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({AppThemes? initial}) {
    ThemePresetRegistry.registerAll();
    _active = AppThemeRegistry.get(initial ?? AppThemes.defaultTheme);
  }

  late AppTheme _active;

  AppTheme get theme => _active;

  AppThemes get activeTheme => _active.id;

  ThemePalette get colors => _active.palette;

  ThemeRadius get radius => _active.radius;

  ThemeSpacing get spacing => _active.spacing;

  ThemeData get themeData => _active.toThemeData();

  void setTheme(AppThemes theme) {
    if (_active.id == theme) return;
    _active = AppThemeRegistry.get(theme);
    notifyListeners();
  }
}
