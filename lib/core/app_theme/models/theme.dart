import 'package:flutter/material.dart' show Color;
import 'package:equatable/equatable.dart';

part 'theme_palette.dart';
part 'theme_spacing.dart';
part 'theme_radius.dart';

class AppTheme {
  const AppTheme({
    this.spacing = const ThemeSpacing(),
    this.radius = const ThemeRadius(),
    required this.palette,
  });

  final ThemeSpacing spacing;
  final ThemePalette palette;
  final ThemeRadius radius;

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
