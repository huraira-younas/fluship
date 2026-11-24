import 'package:material_ui/material_ui.dart' show Color;
import 'package:equatable/equatable.dart';

part 'theme_palette.dart';
part 'theme_spacing.dart';
part 'theme_radius.dart';

class const AppTheme({
  final ThemeSpacing spacing = const ThemeSpacing(),
  final ThemeRadius radius = const ThemeRadius(),
  required final ThemePalette palette,
}) {
  Color get codeBg => palette.codeBg;

  Color get codeBorder => palette.codeBorder;

  Color get inputBg => Color.lerp(palette.bg, palette.hover, 0.32)!;

  Color get inputBorder => palette.cardBorder;

  Map<int, Color> get headingColors => {
    2: palette.section,
    1: palette.accent,
    3: palette.accent,
  };
}
