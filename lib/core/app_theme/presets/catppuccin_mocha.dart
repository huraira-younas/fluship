import '../interfaces/theme_preset_module.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class CatppuccinMochaPreset implements ThemePresetModule {
  const CatppuccinMochaPreset();

  @override
  AppTheme get preset => AppTheme(
    name: 'catppuccin_mocha',
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
