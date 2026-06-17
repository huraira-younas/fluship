import '../interfaces/theme_preset_module.dart';
import '../models/app_themes.dart';
import '../utils/color_from_hex.dart';
import '../models/theme.dart';

final class GitHubPreset implements ThemePresetModule {
  const GitHubPreset();

  @override
  AppThemes get id => AppThemes.github;

  @override
  AppTheme get lightTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#d0d7de'),
      consoleInner: colorFromHex('#f6f8fa'),
      accentHover: colorFromHex('#0550ae'),
      dangerHover: colorFromHex('#a40e26'),
      cardBorder: colorFromHex('#d0d7de'),
      consoleBg: colorFromHex('#f6f8fa'),
      disabled: colorFromHex('#eaeef2'),
      textDim: colorFromHex('#636c76'),
      section: colorFromHex('#57606a'),
      success: colorFromHex('#1a7f37'),
      cardBg: colorFromHex('#ffffff'),
      accent: colorFromHex('#0969da'),
      danger: colorFromHex('#cf222e'),
      error: colorFromHex('#cf222e'),
      hover: colorFromHex('#eaeef2'),
      muted: colorFromHex('#656d76'),
      text: colorFromHex('#1f2328'),
      warn: colorFromHex('#9a6700'),
      cmd: colorFromHex('#0550ae'),
      bg: colorFromHex('#ffffff'),
    ),
  );

  @override
  AppTheme get darkTheme => AppTheme(
    palette: ThemePalette(
      consoleBorder: colorFromHex('#30363d'),
      consoleInner: colorFromHex('#161b22'),
      accentHover: colorFromHex('#4493f8'),
      dangerHover: colorFromHex('#ff7b72'),
      cardBorder: colorFromHex('#30363d'),
      consoleBg: colorFromHex('#0d1117'),
      disabled: colorFromHex('#161b22'),
      textDim: colorFromHex('#6e7681'),
      section: colorFromHex('#8b949e'),
      success: colorFromHex('#3fb950'),
      cardBg: colorFromHex('#161b22'),
      accent: colorFromHex('#2f81f7'),
      danger: colorFromHex('#f85149'),
      error: colorFromHex('#f85149'),
      hover: colorFromHex('#21262d'),
      muted: colorFromHex('#8b949e'),
      text: colorFromHex('#e6edf3'),
      warn: colorFromHex('#d29922'),
      cmd: colorFromHex('#79c0ff'),
      bg: colorFromHex('#0d1117'),
    ),
  );
}
