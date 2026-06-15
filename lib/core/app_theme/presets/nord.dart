import '../interfaces/theme_preset_module.dart';
import '../models/app_themes.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class NordPreset implements ThemePresetModule {
  const NordPreset();

  @override
  AppThemes get id => AppThemes.nord;

  @override
  AppTheme get preset => AppTheme(
    id: id,
    palette: ThemePalette(
      consoleBorder: colorFromHex('#3b4252'),
      consoleInner: colorFromHex('#242933'),
      accentHover: colorFromHex('#88c0d0'),
      dangerHover: colorFromHex('#d08770'),
      cardBorder: colorFromHex('#3b4252'),
      consoleBg: colorFromHex('#2e3440'),
      disabled: colorFromHex('#2e3440'),
      textDim: colorFromHex('#616e88'),
      section: colorFromHex('#e5e9f0'),
      success: colorFromHex('#a3be8c'),
      cardBg: colorFromHex('#3b4252'),
      accent: colorFromHex('#81a1c1'),
      danger: colorFromHex('#bf616a'),
      error: colorFromHex('#bf616a'),
      hover: colorFromHex('#434c5e'),
      muted: colorFromHex('#7b88a1'),
      text: colorFromHex('#eceff4'),
      warn: colorFromHex('#ebcb8b'),
      cmd: colorFromHex('#88c0d0'),
      bg: colorFromHex('#2e3440'),
    ),
  );
}
