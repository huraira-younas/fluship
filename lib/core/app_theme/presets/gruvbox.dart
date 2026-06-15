import '../interfaces/theme_preset_module.dart';
import '../models/app_themes.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class GruvboxPreset implements ThemePresetModule {
  const GruvboxPreset();

  @override
  AppThemes get id => AppThemes.gruvbox;

  @override
  AppTheme get preset => AppTheme(
    id: id,
    palette: ThemePalette(
      consoleBorder: colorFromHex('#3c3836'),
      consoleInner: colorFromHex('#1d2021'),
      accentHover: colorFromHex('#83a598'),
      dangerHover: colorFromHex('#fb4934'),
      cardBorder: colorFromHex('#3c3836'),
      consoleBg: colorFromHex('#1d2021'),
      disabled: colorFromHex('#282828'),
      textDim: colorFromHex('#665c54'),
      section: colorFromHex('#d5c4a1'),
      success: colorFromHex('#b8bb26'),
      cardBg: colorFromHex('#282828'),
      accent: colorFromHex('#83a598'),
      danger: colorFromHex('#cc241d'),
      error: colorFromHex('#fb4934'),
      hover: colorFromHex('#3c3836'),
      muted: colorFromHex('#928374'),
      text: colorFromHex('#ebdbb2'),
      warn: colorFromHex('#fabd2f'),
      cmd: colorFromHex('#8ec07c'),
      bg: colorFromHex('#282828'),
    ),
  );
}
