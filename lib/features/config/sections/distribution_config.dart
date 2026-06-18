import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/widgets/app_text.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/switch_labels_row.dart';
import '../widgets/checkbox_label.dart';
import '../widgets/switch_label.dart';
import '../bloc/config_bloc.dart';

class DistributionConfig extends StatelessWidget {
  const DistributionConfig({super.key});

  GoogleDriveConfig _drive(GoogleDriveConfig? config) =>
      config ?? const GoogleDriveConfig();

  ReportRecipientConfig _report(ReportRecipientConfig? config) =>
      config ?? const ReportRecipientConfig();

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, DistributionConfigModel>(
      selector: (state) => state.distribution,
      builder: (context, distribution) {
        final report = _report(distribution.reportRecipient);
        final drive = _drive(distribution.driveConfig);

        return AppCard(
          state: AppCardState(
            onEnable: (value) => bloc.add(
              UpdateConfig(config: distribution.copyWith(enabled: value)),
            ),
            enable: distribution.enabled,
            forceDisabled: false,
          ),
          title: "Distribution Config",
          description:
              "Choose where Fluship sends your build after compilation: Google Play, App Store, or Google Drive. "
              "Play Store supports production and internal tracks; App Store builds are uploaded to TestFlight for beta testers and review. "
              "Enable Google Drive to share the artifact with your team - expand recipients below to pick who receives it.",
          children: [
            SwitchLabelsRow<PlayStoreDistribution>(
              labels: PlayStoreDistribution.values,
              disabled: !distribution.enabled,
              value: distribution.playstore,
              switchLabel: 'Play Store',
              defaultValue: .production,
              onChange: (value) => bloc.add(
                UpdateConfig(
                  config: distribution.copyWith(
                    clearPlaystore: value == null,
                    playstore: value,
                  ),
                ),
              ),
            ),
            SwitchLabel(
              disabled: !distribution.enabled,
              value: distribution.appstore,
              label: "App Store → TestFlight",
              onChange: (value) => bloc.add(
                UpdateConfig(config: distribution.copyWith(appstore: value)),
              ),
            ),
            SwitchLabel(
              disabled: !distribution.enabled,
              value: drive.enabled,
              label: "Google Drive",
              onChange: (value) => bloc.add(
                UpdateConfig(
                  config: distribution.copyWith(
                    driveConfig: drive.copyWith(enabled: value),
                  ),
                ),
              ),
            ),
            if (drive.enabled && report.emails.isNotEmpty)
              _DriveRecipientsPanel(
                disabled: !distribution.enabled,
                emails: report.emails,
                onToggle: (email, enabled) => bloc.add(
                  UpdateConfig(
                    config: distribution.copyWith(
                      reportRecipient: report.copyWith(
                        emails: report.emails.map((e) {
                          return e.email == email.email
                              ? e.copyWith(enabled: enabled)
                              : e;
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DriveRecipientsPanel extends StatefulWidget {
  const _DriveRecipientsPanel({
    required this.onToggle,
    required this.disabled,
    required this.emails,
  });

  final void Function(DistributionEmail email, bool enabled) onToggle;
  final List<DistributionEmail> emails;
  final bool disabled;

  @override
  State<_DriveRecipientsPanel> createState() => _DriveRecipientsPanelState();
}

class _DriveRecipientsPanelState extends State<_DriveRecipientsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.emails.length;
    final ft = context.flushipTheme;

    return Container(
      decoration: BoxDecoration(
        border: .all(color: ft.colors.cardBorder),
        borderRadius: .circular(ft.radius.btn),
        color: ft.colors.consoleBg,
      ),
      margin: const .only(top: 8),
      child: AnimatedCrossFade(
        crossFadeState: _expanded ? .showSecond : .showFirst,
        duration: const Duration(milliseconds: 250),
        sizeCurve: Curves.easeInOut,
        firstChild: _RecipientsHeader(
          key: const ValueKey('collapsed'),
          actionLabel: 'Show',
          total: total,
          onAction: !widget.disabled
              ? () => setState(() => _expanded = true)
              : null,
        ),
        secondChild: Column(
          key: const ValueKey('expanded'),
          crossAxisAlignment: .stretch,
          children: [
            _RecipientsHeader(
              onAction: () => setState(() => _expanded = false),
              actionLabel: 'Hide',
              total: total,
            ),
            const SizedBox(height: 8),
            ...List.generate(widget.emails.length, (index) {
              final email = widget.emails[index];
              return Column(
                children: [
                  if (index > 0)
                    Divider(height: 1, color: ft.colors.cardBorder),
                  CheckboxLabel(
                    onChange: (value) => widget.onToggle(email, value),
                    disabled: widget.disabled,
                    subtitle: email.email,
                    value: email.enabled,
                    label: email.name,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RecipientsHeader extends StatelessWidget {
  const _RecipientsHeader({
    required this.actionLabel,
    required this.onAction,
    required this.total,
    super.key,
  });

  final VoidCallback? onAction;
  final String actionLabel;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Row(
      children: <Widget>[
        AppText.custom(
          color: ft.colors.section,
          'Drive recipients',
          weight: .w600,
        ),
        const Spacer(),
        AppText.custom(
          color: ft.colors.textDim,
          size: .caption,
          '$total total',
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: ft.colors.accent,
            padding: const .symmetric(horizontal: 8),
            tapTargetSize: .shrinkWrap,
            visualDensity: .compact,
          ),
          child: Text(actionLabel),
        ),
      ],
    ).padSym(h: ft.spacing.md, v: ft.spacing.sm);
  }
}
