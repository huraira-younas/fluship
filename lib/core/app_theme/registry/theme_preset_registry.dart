import '../interfaces/theme_preset_module.dart';
import '../presets/exports.dart';
import 'app_theme_registry.dart';

class ThemePresetRegistry {
  ThemePresetRegistry._();

  static const List<ThemePresetModule> modules = [
    CatppuccinMochaPreset(),
    SolarizedDarkPreset(),
    TokyoNightPreset(),
    OneDarkPreset(),
    GruvboxPreset(),
    DraculaPreset(),
    NordPreset(),
  ];

  static void registerAll() {
    if (!AppThemeRegistry.isEmpty) return;

    for (final module in modules) {
      AppThemeRegistry.register(module.preset);
    }
  }
}
