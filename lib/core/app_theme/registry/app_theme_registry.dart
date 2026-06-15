import '../models/theme.dart';

class AppThemeRegistry {
  AppThemeRegistry._();

  static final Map<String, AppTheme> _themes = {};

  static bool get isEmpty => _themes.isEmpty;

  static void register(AppTheme theme) {
    _themes[theme.name] = theme;
  }

  static AppTheme get(String name) {
    final theme = _themes[name];
    if (theme == null) {
      final available = _themes.keys.toList()..sort();
      throw ArgumentError(
        'Unknown theme "$name". Available: ${available.join(", ")}',
      );
    }

    return theme;
  }

  static List<String> get availableThemes {
    final names = _themes.keys.toList();
    names.sort();
    return names;
  }
}
