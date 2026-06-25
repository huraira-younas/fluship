import 'dart:io' show Platform;

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

  static const _playStoreCredError =
      'Configure package name and service account JSON in Settings.';
  static const _driveCredError =
      'No OAuth JSON found. Please configure Google Drive in the Settings tab.';
  static const _buildReportCredError =
      'Configure Gmail and report recipient in Settings.';
  static const _appStoreCredError =
      'No API key found. Please configure iOS credentials in the Settings tab.';

  void _updateDistribution(
    DistributionConfigModel distribution,
    ConfigBloc bloc,
  ) {
    bloc.add(UpdateConfig(config: distribution));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, DistributionConfigModel>(
      selector: (state) => state.distribution,
      builder: (context, dist) {
        final report = dist.reportRecipient ?? const ReportRecipientConfig();
        final playstore = dist.playstore ?? const GooglePlayConsoleConfig();
        final drive = dist.driveConfig ?? const GoogleDriveConfig();
        final ios = dist.appstore ?? const IosConfig();

        final canBuildReport = dist.canSendBuildReport;
        final canAppStore = dist.canSendToAppStore;
        final canPlay = dist.canSendToPlayStore;
        final canDrive = dist.canSendToDrive;
        final sectionEnabled = dist.enabled;

        return AppCard(
          state: AppCardState(
            onEnable: (value) =>
                _updateDistribution(dist.copyWith(enabled: value), bloc),
            enable: dist.enabled,
            forceDisabled: false,
          ),
          title: "Distribution Config",
          description:
              "Choose where Fluship sends your build after compilation: Google Play, App Store, or Google Drive. "
              "Play Store supports production and internal tracks; App Store builds are uploaded to TestFlight for beta testers and review. "
              "Enable Google Drive to share the artifact with your team - expand recipients below to pick who receives it.",
          children: [
            SwitchLabelsRow<PlayStoreDistribution>(
              value: canPlay ? playstore.distribution : null,
              error: canPlay ? null : _playStoreCredError,
              disabled: !sectionEnabled || !canPlay,
              labels: PlayStoreDistribution.values,
              switchLabel: 'Play Store',
              defaultValue: .production,
              onChange: (value) => _updateDistribution(
                dist.copyWith(
                  playstore: playstore.copyWith(distribution: value),
                ),
                bloc,
              ),
            ),
            if (Platform.isMacOS)
              SwitchLabel(
                error: canAppStore ? null : _appStoreCredError,
                disabled: !sectionEnabled || !canAppStore,
                value: canAppStore && ios.enabled,
                label: "App Store → TestFlight",
                onChange: (value) => _updateDistribution(
                  dist.copyWith(appstore: ios.copyWith(enabled: value)),
                  bloc,
                ),
              ),
            SwitchLabel(
              label: "Google Drive",
              value: canDrive && drive.enabled,
              disabled: !sectionEnabled || !canDrive,
              error: canDrive ? null : _driveCredError,
              onChange: (value) => _updateDistribution(
                dist.copyWith(driveConfig: drive.copyWith(enabled: value)),
                bloc,
              ),
            ),
            if (canDrive && drive.enabled && report.emails.isNotEmpty)
              _DriveRecipientsPanel(
                disabled: !sectionEnabled,
                emails: report.emails,
                onToggle: (email, enabled) => _updateDistribution(
                  dist.copyWith(
                    reportRecipient: report.copyWith(
                      emails: [
                        for (final e in report.emails)
                          if (e.email == email.email)
                            e.copyWith(enabled: enabled)
                          else
                            e,
                      ],
                    ),
                  ),
                  bloc,
                ),
              ),
            SwitchLabel(
              label:
                  "Build Report → ${report.reportRecipient ?? 'Set Recipient'}",
              error: canBuildReport ? null : _buildReportCredError,
              disabled: !sectionEnabled || !canBuildReport,
              value: canBuildReport && report.buildReport,
              onChange: (value) => _updateDistribution(
                dist.copyWith(
                  reportRecipient: report.copyWith(buildReport: value),
                ),
                bloc,
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
    final ft = context.flushipTheme;
    final total = widget.emails.length;

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
          onAction: widget.disabled
              ? null
              : () => setState(() => _expanded = true),
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
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: ft.colors.cardBorder),
              itemCount: widget.emails.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final email = widget.emails[index];
                return CheckboxLabel(
                  onChange: (value) => widget.onToggle(email, value),
                  disabled: widget.disabled,
                  subtitle: email.email,
                  value: email.enabled,
                  label: email.name,
                );
              },
            ),
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
