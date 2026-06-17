import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:flutter/material.dart';

import 'theme_swatch.dart';

class ThemeSwatchRow extends StatelessWidget {
  const ThemeSwatchRow({
    required this.palette,
    required this.gap,
    required this.radius,
    super.key,
  });

  final ThemePalette palette;
  final double gap;
  final double radius;

  static const _minSwatchSize = 14.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final swatchCount = palette.previewSwatches.length;
        final gapTotal = gap * (swatchCount - 1);
        final size = ((constraints.maxWidth - gapTotal) / swatchCount).clamp(
          _minSwatchSize,
          double.infinity,
        );

        return Row(
          spacing: gap,
          children: palette.previewSwatches
              .map(
                (color) =>
                    ThemeSwatch(color: color, radius: radius, size: size),
              )
              .toList(),
        );
      },
    );
  }
}
