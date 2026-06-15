import '../interfaces/theme_preset_module.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class OneDarkPreset implements ThemePresetModule {
  const OneDarkPreset();

  @override
  AppTheme get preset => AppTheme(
    name: 'one_dark',
    palette: ThemePalette(
      consoleBorder: colorFromHex('#3e4452'),
      consoleInner: colorFromHex('#1b1d23'),
      accentHover: colorFromHex('#61afef'),
      dangerHover: colorFromHex('#e06c75'),
      cardBorder: colorFromHex('#3e4452'),
      consoleBg: colorFromHex('#21252b'),
      disabled: colorFromHex('#21252b'),
      textDim: colorFromHex('#5c6370'),
      section: colorFromHex('#abb2bf'),
      success: colorFromHex('#98c379'),
      cardBg: colorFromHex('#21252b'),
      accent: colorFromHex('#61afef'),
      danger: colorFromHex('#e06c75'),
      error: colorFromHex('#e06c75'),
      hover: colorFromHex('#3e4452'),
      muted: colorFromHex('#5c6370'),
      text: colorFromHex('#abb2bf'),
      warn: colorFromHex('#e5c07b'),
      cmd: colorFromHex('#56b6c2'),
      bg: colorFromHex('#282c34'),
    ),
  );
}
