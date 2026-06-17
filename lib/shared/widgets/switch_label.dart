import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/material.dart';

import 'app_text.dart';

class SwitchLabel extends StatelessWidget {
  const SwitchLabel({
    required this.onChange,
    this.disabled = false,
    required this.label,
    required this.value,
    super.key,
  });

  final ValueChanged<bool> onChange;
  final bool disabled;
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: .circular(ft.radius.btn)),
        onTap: disabled ? null : () => onChange(!value),
        visualDensity: .compact,
        contentPadding: .zero,
        title: AppText.custom(
          color: disabled || !value ? ft.colors.textDim : ft.colors.section,
          label,
        ),
        leading: Switch(
          inactiveTrackColor: ft.colors.cardBorder,
          inactiveThumbColor: ft.colors.textDim,
          onChanged: disabled ? null : onChange,
          activeThumbColor: ft.colors.accent,
          value: value,
        ),
      ),
    );
  }
}
