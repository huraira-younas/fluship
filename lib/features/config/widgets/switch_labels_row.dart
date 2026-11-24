import 'package:fluship/core/responsive/widgets/responsive_builder.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_tabs.dart';
import 'package:material_ui/material_ui.dart';

import 'switch_label.dart';

class const SwitchLabelsRow<T>({
  final EdgeInsets contentPadding = const .symmetric(
    horizontal: 20,
    vertical: 4,
  ),
  required final T defaultValue,
  required final String switchLabel,
  required final ValueChanged<T?> onChange,
  final bool disabled = false,
  required final List<T> labels,
  required final T? value,
  final double spacing = 10,
  final String? error,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sw = SwitchLabel(
      onChange: (e) => onChange(e ? defaultValue : null),
      value: value != null,
      disabled: disabled,
      label: switchLabel,
      error: error,
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
