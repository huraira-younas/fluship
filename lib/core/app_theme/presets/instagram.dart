import '../interfaces/theme_preset_module.dart';
import '../models/app_themes.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class InstagramPreset implements ThemePresetModule {
  const InstagramPreset();

  @override
  AppThemes get id => AppThemes.instagram;

  @override
  AppTheme get lightTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#dbdbdb'),
      consoleInner: colorFromHex('#ffffff'),
      accentHover: colorFromHex('#1877f2'),
      dangerHover: colorFromHex('#c13544'),
      cardBorder: colorFromHex('#dbdbdb'),
      consoleBg: colorFromHex('#fafafa'),
      disabled: colorFromHex('#efefef'),
      textDim: colorFromHex('#737373'),
      section: colorFromHex('#363636'),
      success: colorFromHex('#00a862'),
      cardBg: colorFromHex('#ffffff'),
      accent: colorFromHex('#0095f6'),
      danger: colorFromHex('#ed4956'),
      error: colorFromHex('#ed4956'),
      hover: colorFromHex('#f5f5f5'),
      muted: colorFromHex('#8e8e8e'),
      text: colorFromHex('#262626'),
      warn: colorFromHex('#f59e0b'),
      cmd: colorFromHex('#0095f6'),
      bg: colorFromHex('#fafafa'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#363636'),
      consoleInner: colorFromHex('#121212'),
      accentHover: colorFromHex('#47b5ff'),
      dangerHover: colorFromHex('#ff6874'),
      cardBorder: colorFromHex('#363636'),
      consoleBg: colorFromHex('#0a0a0a'),
      disabled: colorFromHex('#262626'),
      textDim: colorFromHex('#a8a8a8'),
      section: colorFromHex('#c7c7c7'),
      success: colorFromHex('#2ecc71'),
      cardBg: colorFromHex('#1a1a1a'),
      accent: colorFromHex('#0095f6'),
      danger: colorFromHex('#ed4956'),
      error: colorFromHex('#ed4956'),
      hover: colorFromHex('#262626'),
      muted: colorFromHex('#737373'),
      text: colorFromHex('#f5f5f5'),
      warn: colorFromHex('#f59e0b'),
      cmd: colorFromHex('#47b5ff'),
      bg: colorFromHex('#121212'),
    ),
  );
}
