import '../interfaces/theme_preset_module.dart';
import '../models/app_themes.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class NordPreset implements ThemePresetModule {
  const NordPreset();

  @override
  AppThemes get id => .nord;

  @override
  AppTheme get lightTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#d8dee9'),
      consoleInner: colorFromHex('#e5e9f0'),
      accentHover: colorFromHex('#81a1c1'),
      dangerHover: colorFromHex('#d08770'),
      cardBorder: colorFromHex('#d8dee9'),
      consoleBg: colorFromHex('#d8dee9'),
      disabled: colorFromHex('#e5e9f0'),
      textDim: colorFromHex('#4c566a'),
      section: colorFromHex('#434c5e'),
      success: colorFromHex('#a3be8c'),
      cardBg: colorFromHex('#e5e9f0'),
      accent: colorFromHex('#5e81ac'),
      danger: colorFromHex('#bf616a'),
      error: colorFromHex('#bf616a'),
      hover: colorFromHex('#d8dee9'),
      muted: colorFromHex('#616e88'),
      text: colorFromHex('#2e3440'),
      warn: colorFromHex('#ebcb8b'),
      cmd: colorFromHex('#88c0d0'),
      bg: colorFromHex('#eceff4'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
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
