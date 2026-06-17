import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:flutter/material.dart';

class ThemePreviewCanvas extends StatelessWidget {
  const ThemePreviewCanvas({
    required this.palette,
    required this.height,
    required this.radius,
    super.key,
  });

  final ThemePalette palette;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.bg, palette.cardBg, palette.consoleBg],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    _Dot(color: palette.danger),
                    _Dot(color: palette.warn),
                    _Dot(color: palette.success),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: palette.hover.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Line(color: palette.accent, text: 'class Fluship {'),
                const SizedBox(height: 3),
                _Line(
                  color: palette.text,
                  text: '   final  pipeline = ["Flutter is Great"];',
                ),
                const SizedBox(height: 3),
                _Line(color: palette.muted, text: '   // Senpai ❤️'),
                const SizedBox(height: 3),
                _Line(color: palette.accent, text: '}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'monospace',
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
        fontSize: 10.5,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
