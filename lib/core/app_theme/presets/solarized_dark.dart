import '../interfaces/theme_preset_module.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class SolarizedDarkPreset implements ThemePresetModule {
  const SolarizedDarkPreset();

  @override
  AppTheme get preset => AppTheme(
    name: 'solarized_dark',
    palette: ThemePalette(
      consoleBorder: colorFromHex('#073642'),
      consoleInner: colorFromHex('#00212b'),
      accentHover: colorFromHex('#268bd2'),
      dangerHover: colorFromHex('#dc322f'),
      cardBorder: colorFromHex('#073642'),
      consoleBg: colorFromHex('#002b36'),
      disabled: colorFromHex('#002b36'),
      textDim: colorFromHex('#586e75'),
      section: colorFromHex('#93a1a1'),
      success: colorFromHex('#859900'),
      accent: colorFromHex('#268bd2'),
      cardBg: colorFromHex('#073642'),
      danger: colorFromHex('#dc322f'),
      error: colorFromHex('#dc322f'),
      hover: colorFromHex('#073642'),
      muted: colorFromHex('#657b83'),
      text: colorFromHex('#fdf6e3'),
      warn: colorFromHex('#b58900'),
      cmd: colorFromHex('#2aa198'),
      bg: colorFromHex('#002b36'),
    ),
  );
}
