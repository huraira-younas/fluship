import '../models/app_themes.dart';
import '../models/theme.dart';

class AppThemeRegistry {
  AppThemeRegistry._();

  static final Map<AppThemes, AppTheme> _themes = {};

  static bool get isEmpty => _themes.isEmpty;

  static void register(AppTheme theme) {
    _themes[theme.id] = theme;
  }

  static AppTheme get(AppThemes id) {
    final theme = _themes[id];
    if (theme == null) {
      final available = _themes.keys.map((id) => id.key).toList()..sort();
      throw ArgumentError(
        'Unknown theme "${id.key}". Available: ${available.join(", ")}',
      );
    }

    return theme;
  }

  static List<AppThemes> get availableThemes {
    final ids = _themes.keys.toList();
    ids.sort((a, b) => a.key.compareTo(b.key));
    return ids;
  }
}
