import '../interfaces/theme_preset_module.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class DraculaPreset implements ThemePresetModule {
  const DraculaPreset();

  @override
  AppTheme get preset => AppTheme(
    name: 'dracula',
    palette: ThemePalette(
      consoleBorder: colorFromHex('#44475a'),
      consoleInner: colorFromHex('#191a21'),
      accentHover: colorFromHex('#bd93f9'),
      dangerHover: colorFromHex('#ff6e6e'),
      cardBorder: colorFromHex('#44475a'),
      consoleBg: colorFromHex('#21222c'),
      disabled: colorFromHex('#282a36'),
      textDim: colorFromHex('#6272a4'),
      section: colorFromHex('#f8f8f2'),
      success: colorFromHex('#50fa7b'),
      cardBg: colorFromHex('#282a36'),
      accent: colorFromHex('#bd93f9'),
      danger: colorFromHex('#ff5555'),
      error: colorFromHex('#ff5555'),
      hover: colorFromHex('#44475a'),
      muted: colorFromHex('#6272a4'),
      text: colorFromHex('#f8f8f2'),
      warn: colorFromHex('#f1fa8c'),
      cmd: colorFromHex('#8be9fd'),
      bg: colorFromHex('#282a36'),
    ),
  );
}
