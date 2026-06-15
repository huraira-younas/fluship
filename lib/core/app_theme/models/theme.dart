import 'package:flutter/material.dart' show Color;
import 'package:equatable/equatable.dart';

part 'theme_palette.dart';
part 'theme_spacing.dart';
part 'theme_radius.dart';

class AppTheme {
  const AppTheme({
    this.radius = const ThemeRadius(),
    this.pad = const ThemeSpacing(),
    required this.palette,
    required this.name,
  });

  final ThemePalette palette;
  final ThemeRadius radius;
  final ThemeSpacing pad;
  final String name;

  static const defaultThemeName = 'one_dark';

  Color get codeBg => palette.codeBg;

  Color get codeBorder => palette.codeBorder;

  Map<int, Color> get headingColors => {
    2: palette.section,
    1: palette.accent,
    3: palette.accent,
  };
}
