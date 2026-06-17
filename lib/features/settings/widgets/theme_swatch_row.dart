import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:flutter/material.dart';

import 'theme_swatch.dart';

class ThemeSwatchRow extends StatelessWidget {
  const ThemeSwatchRow({
    required this.palette,
    required this.size,
    super.key,
  });

  final ThemePalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: palette.previewSwatches
          .map(
            (color) => ThemeSwatch(
              borderColor: Colors.black.withValues(alpha: 0.25),
              color: color,
              size: size,
            ),
          )
          .toList(),
    );
  }
}
