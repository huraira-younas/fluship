import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/services/process/process.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class ProcessRowTile extends StatelessWidget {
  const ProcessRowTile({required this.onKill, required this.row, super.key});

  final VoidCallback onKill;
  final ProcessRow row;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final color = switch (row.kind) {
      .active => ft.colors.success,
      .orphan => ft.colors.warn,
    };

    return Material(
      color: ft.colors.cardBg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: ft.colors.cardBorder),
        borderRadius: .circular(ft.radius.card),
      ),
      child: InkWell(
        borderRadius: .circular(ft.radius.card),
        onTap: () => _showDetails(context, ft),
        child: Row(
          spacing: ft.spacing.md,
          children: [
            Icon(
              ProcessCommandLabel.iconFor(row.command),
              color: color,
              size: 22,
            ),
            Column(
              crossAxisAlignment: .start,
              spacing: ft.spacing.sm,
              children: [
                Row(
                  spacing: ft.spacing.sm,
                  children: [
                    AppText.body(row.displayName, weight: .w600).expanded(),
                    _badge(ft, color),
                  ],
                ),
                AppText.custom(
                  'PID ${row.pid}'
                  '${row.sessionLabel != null ? ' · ${row.sessionLabel}' : ''}'
                  '${row.depth > 0 ? ' · depth ${row.depth}' : ''}',
                  color: ft.colors.textDim,
                ),
              ],
            ).expanded(),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: ft.colors.danger),
              tooltip: 'Kill process',
              onPressed: onKill,
            ),
          ],
        ).padSym(h: ft.spacing.md, v: ft.spacing.md),
      ),
    ).padOnly(l: row.depth * 18.0, b: ft.spacing.sm);
  }

  Widget _badge(FlushipThemeExtension ft, Color color) {
    return Container(
      padding: .symmetric(horizontal: ft.spacing.sm, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: .circular(ft.radius.btn),
        color: color.withValues(alpha: 0.14),
      ),
      child: AppText.custom(
        size: .caption,
        weight: .w600,
        row.kindLabel,
        color: color,
      ),
    );
  }

  void _showDetails(BuildContext context, FlushipThemeExtension ft) {
    showModalBottomSheet<void>(
      backgroundColor: ft.colors.cardBg,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: .vertical(top: .circular(ft.radius.card)),
      ),
      builder: (ctx) => Column(
        crossAxisAlignment: .stretch,
        spacing: ft.spacing.md,
        mainAxisSize: .min,
        children: [
          AppText.title(row.displayName),
          AppText.custom(color: ft.colors.textDim, row.kindDescription),
          AppText.custom(
            color: ft.colors.textDim,
            'PID ${row.pid} · PPID ${row.ppid}',
          ),
          SelectableText(
            row.command,
            style: TextStyle(color: ft.colors.text, fontSize: 13),
          ),
        ],
      ).padAll(ft.spacing.lg),
    );
  }
}
