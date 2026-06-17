import 'package:fluship/core/responsive/widgets/responsive_builder.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_tabs.dart';
import 'package:flutter/material.dart';
import 'switch_label.dart';

class SwitchLabelsRow<T> extends StatelessWidget {
  const SwitchLabelsRow({
    this.contentPadding = const .symmetric(horizontal: 20, vertical: 4),
    required this.defaultValue,
    required this.switchLabel,
    required this.onChange,
    this.disabled = false,
    required this.labels,
    required this.value,
    this.spacing = 10,
    super.key,
  });

  final ValueChanged<T?> onChange;
  final EdgeInsets contentPadding;
  final String switchLabel;
  final List<T> labels;
  final double spacing;
  final T defaultValue;
  final bool disabled;
  final T? value;

  @override
  Widget build(BuildContext context) {
    final sw = SwitchLabel(
      onChange: (e) => onChange(e ? defaultValue : null),
      value: value != null,
      disabled: disabled,
      label: switchLabel,
    );

    final tabs = AppTabs<T>(
      disabled: disabled || value == null,
      contentPadding: contentPadding,
      onChange: (s) => onChange(s),
      label: value ?? defaultValue,
      scrollPadding: .zero,
      labels: labels,
    );

    return ResponsiveBuilder(
      builder: (context, info) {
        if (info.isMobile) {
          return Column(spacing: spacing, children: <Widget>[sw, tabs]);
        }

        return Row(spacing: spacing, children: <Widget>[sw.expanded(), tabs]);
      },
    );
  }
}
