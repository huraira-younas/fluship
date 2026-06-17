import '../models/app_themes.dart';
import '../models/theme.dart';

abstract interface class ThemePresetModule {
  AppThemes get id;

  AppTheme get lightTheme;
  AppTheme get darkTheme;
}
