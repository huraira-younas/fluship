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
      consoleBorder: colorFromHex('#ccd0da'),
      consoleInner: colorFromHex('#dce0e8'),
      accentHover: colorFromHex('#1860db'),
      dangerHover: colorFromHex('#b91c36'),
      cardBorder: colorFromHex('#bcc0cc'),
      consoleBg: colorFromHex('#e6e9ef'),
      disabled: colorFromHex('#dce0e8'),
      textDim: colorFromHex('#6c6f85'),
      section: colorFromHex('#5c5f77'),
      success: colorFromHex('#40a02b'),
      cardBg: colorFromHex('#ffffff'),
      accent: colorFromHex('#1e66f5'),
      danger: colorFromHex('#d20f39'),
      error: colorFromHex('#d20f39'),
      hover: colorFromHex('#e6e9ef'),
      muted: colorFromHex('#7c7f93'),
      text: colorFromHex('#4c4f69'),
      warn: colorFromHex('#df8e1d'),
      cmd: colorFromHex('#209fb5'),
      bg: colorFromHex('#eff1f5'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#585b70'),
      consoleInner: colorFromHex('#11111b'),
      accentHover: colorFromHex('#b4befe'),
      dangerHover: colorFromHex('#f38ba8'),
      cardBorder: colorFromHex('#585b70'),
      consoleBg: colorFromHex('#181825'),
      disabled: colorFromHex('#313244'),
      textDim: colorFromHex('#9399b2'),
      section: colorFromHex('#bac2de'),
      success: colorFromHex('#a6e3a1'),
      cardBg: colorFromHex('#313244'),
      accent: colorFromHex('#89b4fa'),
      danger: colorFromHex('#f38ba8'),
      error: colorFromHex('#f38ba8'),
      hover: colorFromHex('#45475a'),
      muted: colorFromHex('#7f849c'),
      text: colorFromHex('#cdd6f4'),
      warn: colorFromHex('#f9e2af'),
      cmd: colorFromHex('#89dceb'),
      bg: colorFromHex('#1e1e2e'),
    ),
  );
}
