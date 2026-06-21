import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class SwitchLabel extends StatelessWidget {
  const SwitchLabel({
    required this.onChange,
    this.disabled = false,
    required this.label,
    required this.value,
    this.error,
    super.key,
  });

  final ValueChanged<bool> onChange;
  final String? error;
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
        subtitle: error != null
            ? AppText.custom(color: ft.colors.danger, error!)
            : null,
        leading: Switch(
          onChanged: disabled
              ? null
              : (value) {
                  HapticFeedback.lightImpact();
                  onChange(value);
                },
          trackOutlineColor: WidgetStateProperty.all(
            value ? Colors.transparent : ft.colors.consoleBg,
          ),
          inactiveThumbColor: ft.colors.textDim,
          inactiveTrackColor: ft.colors.codeBg,
          activeThumbColor: ft.colors.accent,
          value: value,
        ),
      ),
    );
  }
}
