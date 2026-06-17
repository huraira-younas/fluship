import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/widgets/app_checkbox.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';


class CheckboxLabel extends StatelessWidget {
  const CheckboxLabel({
    required this.onChange,
    this.disabled = false,
    required this.value,
    required this.label,
    this.subtitle,
    super.key,
  });

  final ValueChanged<bool> onChange;
  final String? subtitle;
  final bool disabled;
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: disabled ? null : () => onChange(!value),
        visualDensity: .compact,
        subtitle: subtitle == null
            ? null
            : AppText.custom(
                color: ft.colors.textDim,
                size: .caption,
                subtitle!,
              ),
        title: AppText.custom(
          color: disabled || !value ? ft.colors.textDim : ft.colors.section,
          label,
        ),
        leading: AppCheckbox(
          onChanged: disabled ? null : onChange,
          disabled: disabled,
          value: value,
        ),
      ),
    );
  }
}
