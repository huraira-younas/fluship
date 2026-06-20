import 'package:flutter/material.dart';

class PipelineProgressIcon extends StatelessWidget {
  const PipelineProgressIcon({
    required this.showSpinner,
    required this.color,
    required this.icon,
    this.size = 20,
    super.key,
  });

  final bool showSpinner;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (showSpinner) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    return Icon(icon, size: size, color: color);
  }
}
