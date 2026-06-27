import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:fluship/core/app_theme/app_theme.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppCardState extends Equatable {
  final ValueChanged<bool> onEnable;
  final bool forceDisabled;
  final bool enable;

  const AppCardState({
    required this.forceDisabled,
    required this.onEnable,
    required this.enable,
  });

  @override
  List<Object?> get props => [enable];
}

class AppCard extends StatelessWidget {
  const AppCard({
    this.expandedBody = false,
    required this.description,
    required this.children,
    required this.title,
    this.spacing = 0,
    this.radius,
    this.border,
    this.height,
    this.width,
    this.state,
    super.key,
  });

  final List<Widget> children;
  final BorderRadius? radius;
  final AppCardState? state;
  final String description;
  final bool expandedBody;
  final Border? border;
  final double? height;
  final double spacing;
  final double? width;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final nn = state != null;

    final body = Column(spacing: spacing, children: children);
    return Container(
      height: height ?? (expandedBody ? double.infinity : null),
      padding: .all(ft.spacing.lg),
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
