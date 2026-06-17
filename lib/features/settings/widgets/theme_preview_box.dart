import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class ThemePreviewBox extends StatelessWidget {
  const ThemePreviewBox({
    required this.displayName,
    required this.palette,
    required this.minHeight,
    required this.textSize,
    required this.radius,
    super.key,
  });

  final AppTextSize textSize;
  final ThemePalette palette;
  final String displayName;
  final double minHeight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: palette.bg,
      ),
      alignment: Alignment.centerLeft,
      child: AppText.custom(
        'Sample text in $displayName',
        color: palette.text,
        size: textSize,
      ),
    );
  }
}
