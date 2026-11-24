import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

class const FieldButton({
  required final VoidCallback onBrowse,
  required final String label,
  required final String hint,
  final String? value,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      crossAxisAlignment: .end,
      children: <Widget>[
        AppTextField.label(
          key: value != null ? ValueKey(value) : null,
          initialValue: value,
          enabled: false,
          label: label,
          hint: hint,
        ).expanded(),
        AppButton.primary(label: "Browse", onPressed: onBrowse).padOnly(b: 3),
      ],
    );
  }
}
