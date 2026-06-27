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
      consoleBorder: colorFromHex('#c9d0db'),
      consoleInner: colorFromHex('#eceff4'),
      accentHover: colorFromHex('#4c6a8a'),
      dangerHover: colorFromHex('#a54e56'),
      cardBorder: colorFromHex('#c9d0db'),
      consoleBg: colorFromHex('#e5e9f0'),
      disabled: colorFromHex('#e5e9f0'),
      textDim: colorFromHex('#4c566a'),
      section: colorFromHex('#434c5e'),
      success: colorFromHex('#2e7d32'),
      cardBg: colorFromHex('#ffffff'),
      accent: colorFromHex('#5e81ac'),
      danger: colorFromHex('#bf616a'),
      error: colorFromHex('#bf616a'),
      hover: colorFromHex('#e5e9f0'),
      muted: colorFromHex('#616e88'),
      text: colorFromHex('#2e3440'),
      warn: colorFromHex('#b58900'),
      cmd: colorFromHex('#0288a7'),
      bg: colorFromHex('#eceff4'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#4c566a'),
      consoleInner: colorFromHex('#242933'),
      accentHover: colorFromHex('#8fbcbb'),
      dangerHover: colorFromHex('#d08770'),
      cardBorder: colorFromHex('#434c5e'),
      consoleBg: colorFromHex('#2e3440'),
      disabled: colorFromHex('#3b4252'),
      textDim: colorFromHex('#d8dee9'),
      section: colorFromHex('#c8d0e0'),
      success: colorFromHex('#a3be8c'),
      cardBg: colorFromHex('#3b4252'),
      accent: colorFromHex('#88c0d0'),
      danger: colorFromHex('#bf616a'),
      error: colorFromHex('#bf616a'),
      hover: colorFromHex('#434c5e'),
      muted: colorFromHex('#a9b4c7'),
      text: colorFromHex('#eceff4'),
      warn: colorFromHex('#ebcb8b'),
      cmd: colorFromHex('#8fbcbb'),
      bg: colorFromHex('#2e3440'),
    ),
  );
}
