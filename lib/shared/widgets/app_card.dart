import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:fluship/core/app_theme/app_theme.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

class const AppCardState({
  required final bool forceDisabled,
  required final ValueChanged<bool> onEnable,
  required final bool enable,
}) extends Equatable {
  @override
  List<Object?> get props => [enable];
}

class const AppCard({
  final bool expandedBody = false,
  required final String description,
  required final List<Widget> children,
  required final String title,
  final double spacing = 0,
  final EdgeInsets? padding,
  final BorderRadius? radius,
  final Border? border,
  final double? height,
  final double? width,
  final AppCardState? state,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final nn = state != null;

    final body = Column(spacing: spacing, children: children);
    return Container(
      height: height ?? (expandedBody ? double.infinity : null),
      padding: padding ?? .all(ft.spacing.lg),
      width: width,
      decoration: BoxDecoration(
        border: border ?? .all(color: ft.colors.cardBorder),
        borderRadius: radius ?? .circular(ft.radius.card),
        color: ft.colors.codeBg,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 4,
        children: [
          Row(
            children: <Widget>[
              AppText.title(title).expanded(),
              if (nn)
                Switch(
                  onChanged: (value) {
                    if (state!.forceDisabled) return;
                    HapticFeedback.lightImpact();
                    state!.onEnable(value);
                  },
                  inactiveTrackColor: ft.colors.cardBorder,
                  inactiveThumbColor: ft.colors.textDim,
                  activeThumbColor: ft.colors.accent,
                  value: state!.enable,
                ),
            ],
          ),
          if (!nn) const SizedBox(height: 6),
          AppText.label(description),
          const SizedBox(height: 16),
          if (expandedBody) body.expanded() else body,
        ],
      ),
    );
  }
}
