import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

class const SwitchLabel({
  required final ValueChanged<bool> onChange,
  final bool disabled = false,
  required final String label,
  required final bool value,
  final String? error,
  super.key,
}) extends StatelessWidget {
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
