import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';

class FieldButton extends StatelessWidget {
  const FieldButton({
    required this.onBrowse,
    required this.label,
    required this.hint,
    super.key,
  });

  final VoidCallback onBrowse;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      crossAxisAlignment: .end,
      children: <Widget>[
        AppTextField.label(hint: hint, label: label, enabled: false).expanded(),
        AppButton.primary(label: "Browse", onPressed: onBrowse).padOnly(b: 3),
      ],
    );
  }
}
