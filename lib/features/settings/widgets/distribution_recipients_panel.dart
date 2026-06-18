import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/widgets/app_cta_button.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

import 'add_recipient_sheet.dart';

class DistributionRecipientsPanel extends StatelessWidget {
  const DistributionRecipientsPanel({
    required this.onChanged,
    required this.emails,
    super.key,
  });

  final ValueChanged<List<DistributionEmail>> onChanged;
  final List<DistributionEmail> emails;

  Future<void> _openAddSheet(BuildContext context) async {
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;

    final recipient = await AddRecipientSheet.show(context);
    if (!context.mounted || recipient == null) return;

    final exists = emails.any(
      (e) => e.email.toLowerCase() == recipient.email.toLowerCase(),
    );
    if (exists) {
      AppToast.warning('This email is already in the list');
      return;
    }

    onChanged([...emails, recipient]);
    AppToast.success('${recipient.name} added to distribution list');
  }

  void _remove(int index) {
    final next = [...emails]..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) {
      return AppCtaButton(
        onTap: () => _openAddSheet(context),
        text:
            'Add people who should receive build artifacts and distribution\n emails after each run.',
        icon: Icons.people_outline_rounded,
        title: 'No recipients yet',
        btnText: 'Add recipient',
        iconSize: 72,
      ).padSym(v: 30);
    }

    final ft = context.flushipTheme;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: ft.spacing.sm,
      children: [
        Row(
          children: [
            AppText.custom(
              'Distribution list',
              color: ft.colors.section,
              weight: .w600,
            ),
            const Spacer(),
            AppText.custom(
              '${emails.length} recipient${emails.length == 1 ? '' : 's'}',
              color: ft.colors.textDim,
              size: .caption,
            ),
          ],
        ),
        ...List.generate(emails.length, (index) {
          final recipient = emails[index];
          return _RecipientTile(
            onRemove: () => _remove(index),
            email: recipient.email,
            name: recipient.name,
          );
        }),
        AppButton.outline(
          leading: Icon(
            Icons.person_add_outlined,
            color: ft.colors.accent,
            size: 18,
          ),
          onPressed: () => _openAddSheet(context),
          label: 'Add recipient',
        ),
      ],
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.onRemove,
    required this.email,
    required this.name,
  });

  final VoidCallback onRemove;
  final String email;
  final String name;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: .circular(ft.radius.input),
        border: .all(color: ft.colors.cardBorder),
        color: ft.colors.consoleBg,
      ),
      padding: .symmetric(
        vertical: ft.spacing.sm + 2,
        horizontal: ft.spacing.md,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ft.colors.accent.withValues(alpha: 0.12),
              borderRadius: .circular(ft.radius.input),
            ),
            padding: .all(ft.spacing.sm),
            child: Icon(
              Icons.person_outline_rounded,
              color: ft.colors.accent,
              size: 20,
            ),
          ),
          SizedBox(width: ft.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AppText.custom(color: ft.colors.section, weight: .w600, name),
                const SizedBox(height: 2),
                AppText.custom(color: ft.colors.textDim, size: .caption, email),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove recipient',
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, color: ft.colors.danger, size: 20),
            visualDensity: .compact,
          ),
        ],
      ),
    );
  }
}
