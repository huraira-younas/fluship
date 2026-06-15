import 'package:flutter/material.dart' show Color;
import 'package:equatable/equatable.dart';

import 'app_themes.dart';

part 'theme_palette.dart';
part 'theme_spacing.dart';
part 'theme_radius.dart';

class AppTheme {
  const AppTheme({
    this.spacing = const ThemeSpacing(),
    this.radius = const ThemeRadius(),
    required this.palette,
    required this.id,
  });

  final ThemeSpacing spacing;
  final ThemePalette palette;
  final ThemeRadius radius;
  final AppThemes id;

  Color get codeBg => palette.codeBg;

  Color get codeBorder => palette.codeBorder;

  Map<int, Color> get headingColors => {
    2: palette.section,
    1: palette.accent,
    3: palette.accent,
  };
}
