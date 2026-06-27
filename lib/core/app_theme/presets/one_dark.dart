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
      consoleBorder: colorFromHex('#dfe1e5'),
      consoleInner: colorFromHex('#fafafa'),
      accentHover: colorFromHex('#3366dd'),
      dangerHover: colorFromHex('#c93d32'),
      cardBorder: colorFromHex('#e4e4e7'),
      consoleBg: colorFromHex('#f4f4f5'),
      disabled: colorFromHex('#f0f0f1'),
      textDim: colorFromHex('#696c77'),
      section: colorFromHex('#45464a'),
      success: colorFromHex('#38944a'),
      cardBg: colorFromHex('#ffffff'),
      accent: colorFromHex('#4078f2'),
      danger: colorFromHex('#e45649'),
      error: colorFromHex('#e45649'),
      hover: colorFromHex('#f0f0f1'),
      muted: colorFromHex('#6a737d'),
      text: colorFromHex('#383a42'),
      warn: colorFromHex('#c18401'),
      cmd: colorFromHex('#0184bc'),
      bg: colorFromHex('#fafafa'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#181a1f'),
      consoleInner: colorFromHex('#1e2127'),
      accentHover: colorFromHex('#7cb8f5'),
      dangerHover: colorFromHex('#e06c75'),
      cardBorder: colorFromHex('#3e4452'),
      consoleBg: colorFromHex('#21252b'),
      disabled: colorFromHex('#2c313a'),
      textDim: colorFromHex('#636872'),
      section: colorFromHex('#abb2bf'),
      success: colorFromHex('#98c379'),
      cardBg: colorFromHex('#21252b'),
      accent: colorFromHex('#61afef'),
      danger: colorFromHex('#e06c75'),
      error: colorFromHex('#e06c75'),
      hover: colorFromHex('#2c313a'),
      muted: colorFromHex('#7f848e'),
      text: colorFromHex('#eceff4'),
      warn: colorFromHex('#e5c07b'),
      cmd: colorFromHex('#56b6c2'),
      bg: colorFromHex('#282c34'),
    ),
  );
}
