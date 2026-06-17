import 'package:flutter/material.dart' show Brightness;

import '../models/app_themes.dart';
import '../models/theme.dart';

class ThemePresetBundle {
  const ThemePresetBundle({required this.light, required this.dark});

  final AppTheme light;
  final AppTheme dark;
}

class AppThemeRegistry {
  AppThemeRegistry._();

  static final Map<AppThemes, ThemePresetBundle> _presets = {};

  static bool get isEmpty => _presets.isEmpty;

  static void registerPreset({
    required AppTheme light,
    required AppTheme dark,
    required AppThemes id,
  }) {
    _presets[id] = ThemePresetBundle(light: light, dark: dark);
  }

  static ThemePresetBundle getBundle(AppThemes id) {
    final bundle = _presets[id];
    if (bundle == null) {
      final available = _presets.keys.map((id) => id.key).toList()..sort();
      throw ArgumentError(
        'Unknown theme "${id.key}". Available: ${available.join(", ")}',
      );
    }

    return bundle;
  }

  static AppTheme get(AppThemes id, {Brightness brightness = Brightness.dark}) {
    final bundle = getBundle(id);
    return brightness == Brightness.light ? bundle.light : bundle.dark;
  }

  static List<AppThemes> get availableThemes {
    final ids = _presets.keys.toList();
    ids.sort((a, b) => a.key.compareTo(b.key));
    return ids;
  }
}
