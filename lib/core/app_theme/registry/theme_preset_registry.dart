import '../interfaces/theme_preset_module.dart';
import '../presets/exports.dart';
import 'app_theme_registry.dart';

class ThemePresetRegistry {
  ThemePresetRegistry._();

  static const List<ThemePresetModule> modules = [
    CatppuccinMochaPreset(),
    InstagramPreset(),
    OneDarkPreset(),
    GitHubPreset(),
    NordPreset(),
  ];

  static void registerAll() {
    if (!AppThemeRegistry.isEmpty) return;

    for (final module in modules) {
      AppThemeRegistry.registerPreset(
        light: module.lightTheme,
        dark: module.darkTheme,
        id: module.id,
      );
    }
  }
}
