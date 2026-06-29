import '../interfaces/theme_preset_module.dart';
import '../utils/color_from_hex.dart';
import '../models/app_themes.dart';
import '../models/theme.dart';

final class CrimsonPreset implements ThemePresetModule {
  const CrimsonPreset();

  @override
  AppThemes get id => .crimson;

  @override
  AppTheme get lightTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#e4e4e7'),
      consoleInner: colorFromHex('#fafafa'),
      accentHover: colorFromHex('#b91c1c'),
      dangerHover: colorFromHex('#9f1239'),
      cardBorder: colorFromHex('#d4d4d8'),
      consoleBg: colorFromHex('#f4f4f5'),
      disabled: colorFromHex('#f0f0f1'),
      textDim: colorFromHex('#71717a'),
      section: colorFromHex('#3f3f46'),
      success: colorFromHex('#15803d'),
      cardBg: colorFromHex('#ffffff'),
      accent: colorFromHex('#dc2626'),
      danger: colorFromHex('#be123c'),
      error: colorFromHex('#be123c'),
      hover: colorFromHex('#f0f0f1'),
      muted: colorFromHex('#a1a1aa'),
      text: colorFromHex('#18181b'),
      warn: colorFromHex('#ca8a04'),
      cmd: colorFromHex('#b91c1c'),
      bg: colorFromHex('#fafafa'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#3f3f46'),
      consoleInner: colorFromHex('#09090b'),
      accentHover: colorFromHex('#fca5a5'),
      dangerHover: colorFromHex('#fda4af'),
      cardBorder: colorFromHex('#3f3f46'),
      consoleBg: colorFromHex('#18181b'),
      disabled: colorFromHex('#27272a'),
      textDim: colorFromHex('#a1a1aa'),
      section: colorFromHex('#d4d4d8'),
      success: colorFromHex('#4ade80'),
      cardBg: colorFromHex('#27272a'),
      accent: colorFromHex('#f87171'),
      danger: colorFromHex('#fb7185'),
      error: colorFromHex('#fb7185'),
      hover: colorFromHex('#3f3f46'),
      muted: colorFromHex('#71717a'),
      text: colorFromHex('#fafafa'),
      warn: colorFromHex('#fbbf24'),
      cmd: colorFromHex('#fca5a5'),
      bg: colorFromHex('#18181b'),
    ),
  );
}
