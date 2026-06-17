import '../interfaces/theme_preset_module.dart';
import '../models/app_themes.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class OneDarkPreset implements ThemePresetModule {
  const OneDarkPreset();

  @override
  AppThemes get id => .oneDark;

  @override
  AppTheme get lightTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#d0d0d0'),
      consoleInner: colorFromHex('#e0e0e0'),
      accentHover: colorFromHex('#0184bc'),
      dangerHover: colorFromHex('#ca1243'),
      cardBorder: colorFromHex('#d0d0d0'),
      consoleBg: colorFromHex('#e8e8e8'),
      disabled: colorFromHex('#f0f0f0'),
      textDim: colorFromHex('#696c77'),
      section: colorFromHex('#505050'),
      success: colorFromHex('#50a14f'),
      cardBg: colorFromHex('#f0f0f0'),
      accent: colorFromHex('#4078f2'),
      danger: colorFromHex('#e45649'),
      error: colorFromHex('#e45649'),
      hover: colorFromHex('#e0e0e0'),
      muted: colorFromHex('#696c77'),
      text: colorFromHex('#2e3440'),
      warn: colorFromHex('#c18401'),
      cmd: colorFromHex('#0184bc'),
      bg: colorFromHex('#fafafa'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
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
      text: colorFromHex('#eceff4'),
      warn: colorFromHex('#e5c07b'),
      cmd: colorFromHex('#56b6c2'),
      bg: colorFromHex('#282c34'),
    ),
  );
}
