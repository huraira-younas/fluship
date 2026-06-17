import '../interfaces/theme_preset_module.dart';
import '../utils/color_from_hex.dart';
import '../models/app_themes.dart';
import '../models/theme.dart';

final class CatppuccinMochaPreset implements ThemePresetModule {
  const CatppuccinMochaPreset();

  @override
  AppThemes get id => .catppuccinMocha;

  @override
  AppTheme get lightTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#bcc0cc'),
      consoleInner: colorFromHex('#ccd0da'),
      accentHover: colorFromHex('#04a5e5'),
      dangerHover: colorFromHex('#d20f39'),
      cardBorder: colorFromHex('#bcc0cc'),
      consoleBg: colorFromHex('#dce0e8'),
      disabled: colorFromHex('#dce0e8'),
      textDim: colorFromHex('#6c6f85'),
      section: colorFromHex('#5c5f77'),
      success: colorFromHex('#40a02b'),
      cardBg: colorFromHex('#e6e9ef'),
      accent: colorFromHex('#1e66f5'),
      danger: colorFromHex('#d20f39'),
      error: colorFromHex('#d20f39'),
      hover: colorFromHex('#ccd0da'),
      muted: colorFromHex('#7c7f93'),
      text: colorFromHex('#4c4f69'),
      warn: colorFromHex('#df8e1d'),
      cmd: colorFromHex('#04a5e5'),
      bg: colorFromHex('#eff1f5'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#313244'),
      consoleInner: colorFromHex('#11111b'),
      accentHover: colorFromHex('#b4befe'),
      dangerHover: colorFromHex('#f38ba8'),
      cardBorder: colorFromHex('#313244'),
      consoleBg: colorFromHex('#181825'),
      disabled: colorFromHex('#1e1e2e'),
      textDim: colorFromHex('#6c7086'),
      section: colorFromHex('#a6adc8'),
      success: colorFromHex('#a6e3a1'),
      cardBg: colorFromHex('#1e1e2e'),
      accent: colorFromHex('#89b4fa'),
      danger: colorFromHex('#f38ba8'),
      error: colorFromHex('#f38ba8'),
      hover: colorFromHex('#313244'),
      muted: colorFromHex('#7f849c'),
      text: colorFromHex('#cdd6f4'),
      warn: colorFromHex('#f9e2af'),
      cmd: colorFromHex('#89dceb'),
      bg: colorFromHex('#1e1e2e'),
    ),
  );
}
