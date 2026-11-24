import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/widgets/app_checkbox.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

class const CheckboxLabel({
  required final ValueChanged<bool> onChange,
  final bool disabled = false,
  required final bool value,
  required final String label,
  final String? subtitle,
  super.key,
}) extends StatelessWidget {
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
