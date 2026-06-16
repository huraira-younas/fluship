import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class CustomLabelWidget extends StatelessWidget {
  const CustomLabelWidget({
    this.iconSize = 100.0,
    required this.title,
    required this.icon,
    required this.text,
    this.btnWidth,
    this.btnText,
    this.color,
    this.onTap,
    super.key,
  });

  final VoidCallback? onTap;
  final double? btnWidth;
  final String? btnText;
  final double iconSize;
  final IconData icon;
  final String title;
  final Color? color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisAlignment: .center,
      children: <Widget>[
        Icon(icon, color: color ?? theme.highlightColor, size: iconSize),
        const SizedBox(height: 24),
        AppText.title(title, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        AppText.body(text, textAlign: TextAlign.center),

        if (btnText != null) ...[
          const SizedBox(height: 30),
          AppButton(onPressed: onTap, label: btnText!, size: .md).center(),
        ],
      ],
    ).padSym(h: 20);
  }
}
