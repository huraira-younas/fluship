import '../interfaces/theme_preset_module.dart';
import '../models/app_themes.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class TokyoNightPreset implements ThemePresetModule {
  const TokyoNightPreset();

  @override
  AppThemes get id => AppThemes.tokyoNight;

  @override
  AppTheme get preset => AppTheme(
    id: id,
    palette: ThemePalette(
      consoleBorder: colorFromHex('#292e42'),
      consoleInner: colorFromHex('#16161e'),
      accentHover: colorFromHex('#89ddff'),
      dangerHover: colorFromHex('#ff7a93'),
      cardBorder: colorFromHex('#292e42'),
      consoleBg: colorFromHex('#1a1b26'),
      disabled: colorFromHex('#1a1b26'),
      textDim: colorFromHex('#565f89'),
      section: colorFromHex('#a9b1d6'),
      success: colorFromHex('#9ece6a'),
      cardBg: colorFromHex('#1a1b26'),
      accent: colorFromHex('#7aa2f7'),
      danger: colorFromHex('#f7768e'),
      error: colorFromHex('#f7768e'),
      hover: colorFromHex('#292e42'),
      muted: colorFromHex('#565f89'),
      text: colorFromHex('#c0caf5'),
      warn: colorFromHex('#e0af68'),
      cmd: colorFromHex('#7dcfff'),
      bg: colorFromHex('#1a1b26'),
    ),
  );
}
