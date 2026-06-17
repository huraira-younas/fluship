import 'package:flutter/material.dart';

class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    required this.color,
    required this.radius,
    required this.size,
    super.key,
  });

  final double radius;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color,
      ),
    );
  }
}
