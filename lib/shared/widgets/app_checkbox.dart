import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/material.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    required this.onChanged,
    this.disabled = false,
    required this.value,
    this.size = 22,
    super.key,
  });

  final ValueChanged<bool>? onChanged;
  final bool disabled;
  final double size;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final canTap = !disabled && onChanged != null;
    final colors = context.flushipTheme.colors;
    final checked = value;

    return GestureDetector(
      onTap: canTap ? () => onChanged!(!value) : null,
      behavior: .opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: .circular(6),
          color: checked
              ? (disabled
                  ? colors.accent.withValues(alpha: 0.35)
                  : colors.accent)
              : colors.cardBg.withValues(alpha: 0.5),
          border: .all(
            width: 1.5,
            color: checked
                ? Colors.transparent
                : (disabled
                    ? colors.cardBorder
                    : colors.textDim.withValues(alpha: 0.55)),
          ),
          boxShadow: checked && !disabled
              ? [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.3),
                    spreadRadius: -2,
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            scale: checked ? 1 : 0,
            child: Icon(
              Icons.check_rounded,
              color: colors.bg,
              size: size * 0.72,
            ),
          ),
        ),
      ),
    );
  }
}
