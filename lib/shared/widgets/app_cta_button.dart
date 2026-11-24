import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

class const AppCtaButton({
  final double iconSize = 100.0,
  required final String title,
  required final IconData icon,
  required final String text,
  final double? btnWidth,
  final String? btnText,
  final Color? color,
  final VoidCallback? onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisAlignment: .center,
      children: <Widget>[
        Icon(icon, color: color ?? theme.highlightColor, size: iconSize),
        const SizedBox(height: 24),
        AppText.title(title, textAlign: .center),
        const SizedBox(height: 10),
        AppText.body(text, textAlign: .center),

        if (btnText != null) ...[
          const SizedBox(height: 30),
          AppButton(onPressed: onTap, label: btnText!, size: .md).center(),
        ],
      ],
    ).padSym(h: 20);
  }
}
