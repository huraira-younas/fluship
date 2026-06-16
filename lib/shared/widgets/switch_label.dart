import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/material.dart';

import 'app_text.dart';

class SwitchLabel extends StatelessWidget {
  const SwitchLabel({
    required this.onChange,
    required this.label,
    required this.value,
    super.key,
  });

  final ValueChanged<bool> onChange;
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return ListTile(
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      onTap: () => onChange(!value),
      title: AppText.body(label),
      leading: Switch(
        inactiveTrackColor: ft.colors.cardBorder,
        inactiveThumbColor: ft.colors.textDim,
        activeThumbColor: ft.colors.accent,
        onChanged: onChange,
        value: value,
      ),
    );
  }
}
