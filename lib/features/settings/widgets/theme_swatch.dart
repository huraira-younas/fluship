import 'package:flutter/material.dart';

class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    required this.color,
    required this.size,
    this.borderColor,
    super.key,
  });

  final Color? borderColor;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1),
        color: color,
      ),
    );
  }
}
