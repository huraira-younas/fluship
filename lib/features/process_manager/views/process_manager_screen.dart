import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/services/process/process.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../bloc/process_manager_bloc.dart';
import '../widgets/process_row.dart';

class ProcessManagerScreen extends StatefulWidget {
  const ProcessManagerScreen({super.key});

  @override
  State<ProcessManagerScreen> createState() => _ProcessManagerScreenState();
}

class _ProcessManagerScreenState extends State<ProcessManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncVisibility(true);
    });
  }

  @override
  void dispose() {
    getIt<ProcessManagerBloc>().add(
      const ProcessManagerVisibilityChanged(isVisible: false),
    );
    super.dispose();
  }

  void _syncVisibility(bool visible) {
    final bloc = getIt<ProcessManagerBloc>();
    final projectRoot =
        context.read<ConfigBloc>().state.appInfo.flutterProjectPath ?? '';

    bloc.add(ProcessManagerVisibilityChanged(isVisible: visible));
    bloc.add(ProcessManagerInitialized(projectRoot: projectRoot));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ProcessManagerBloc>(),
      child: const _ProcessManagerView(),
    );
  }
}

class _ProcessManagerView extends StatelessWidget {
  const _ProcessManagerView();

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return BlocConsumer<ProcessManagerBloc, ProcessManagerState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (_, state) {
        AppToast.error(state.error!.message, title: state.error!.title);
      },
      builder: (context, state) {
        if (!state.isSupported) {
          return const AppText.body(
            'Process monitoring is only available on desktop platforms.',
          ).center();
        }

        return Column(
          crossAxisAlignment: .stretch,
          spacing: ft.spacing.md,
          children: [
            _buildToolbar(context, ft, state),
            _buildSummary(ft, state),
            if (state.loading && state.processes.isEmpty)
              const LinearProgressIndicator().padOnly(b: ft.spacing.sm),
            _buildBody(context, ft, state).expanded(),
          ],
        );
      },
    );
  }

  Widget _buildSummary(FlushipThemeExtension ft, ProcessManagerState state) {
    return Row(
      spacing: ft.spacing.sm,
      children: [
        _summaryChip(
          label: '${state.actives.length} active',
          icon: Icons.play_circle_outline_rounded,
          color: ft.colors.success,
          ft,
        ),
        _summaryChip(
          label: '${state.orphans.length} orphans',
          icon: Icons.warning_amber_rounded,
          color: ft.colors.warn,
          ft,
        ),
      ],
    );
  }

  Widget _summaryChip(
    FlushipThemeExtension ft, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: .symmetric(horizontal: ft.spacing.md, vertical: ft.spacing.sm),
      decoration: BoxDecoration(
        border: .all(color: color.withValues(alpha: 0.35)),
        borderRadius: .circular(ft.radius.btn),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        spacing: ft.spacing.sm,
        children: [
          Icon(icon, size: 16, color: color),
          AppText.custom(color: color, label, weight: .w600),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    FlushipThemeExtension ft,
    ProcessManagerState state,
  ) {
    final bloc = context.read<ProcessManagerBloc>();
    final projectRoot =
        context.watch<ConfigBloc>().state.appInfo.flutterProjectPath ?? '';

    return Row(
      spacing: ft.spacing.md,
      children: [
        AppText.custom(
          color: ft.colors.textDim,
          projectRoot.isEmpty
              ? 'Set project path in Settings to detect orphan leftovers.'
              : projectRoot,
        ).expanded(),
        const AppText.body('Non-build children'),
        Switch(
          trackOutlineColor: WidgetStateProperty.all(
            state.showAllChildren ? Colors.transparent : ft.colors.consoleBg,
          ),
          inactiveThumbColor: ft.colors.textDim,
          inactiveTrackColor: ft.colors.codeBg,
          activeThumbColor: ft.colors.accent,
          value: state.showAllChildren,
          onChanged: (value) =>
              bloc.add(ProcessManagerShowAllChildrenToggled(value: value)),
        ),
        AppButton.icon(
          onPressed: () =>
              bloc.add(ProcessManagerRefreshed(projectRoot: projectRoot)),
          leading: const Icon(Icons.refresh_rounded),
          variant: .outline,
        ),
        if (state.orphans.isNotEmpty)
          AppButton.danger(
            label: 'Kill orphans (${state.orphans.length})',
            onPressed: () => _confirmKillOrphans(context, bloc),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    FlushipThemeExtension ft,
    ProcessManagerState state,
  ) {
    if (state.processes.isEmpty && !state.loading) {
      return Column(
        mainAxisAlignment: .center,
        spacing: ft.spacing.sm,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: ft.colors.textDim),
          const AppText.body('No Fluship processes running.'),
          AppText.custom(
            color: ft.colors.textDim,
            'Start a pipeline to see active processes here. Orphans appear after a cancelled build.',
          ).center(),
        ],
      );
    }

    final bloc = context.read<ProcessManagerBloc>();

    return ListView(
      children: [
        if (state.actives.isNotEmpty) ...[
          _sectionHeader(
            subtitle:
                'Running under Fluship pipeline or console - killing stops the build.',
            color: ft.colors.success,
            title: 'Active',
            ft,
          ),
          ...state.actives.map(
            (row) => ProcessRowTile(
              onKill: () => _confirmKill(bloc, context, row),
              row: row,
            ),
          ),
        ],
        if (state.orphans.isNotEmpty) ...[
          _sectionHeader(
            subtitle:
                'Leftover from a previous Fluship run. Not linked to any shell - safe to kill.',
            color: ft.colors.warn,
            title: 'Orphans',
            ft,
          ),
          ...state.orphans.map(
            (row) => ProcessRowTile(
              onKill: () => bloc.add(ProcessManagerKillProcess(pid: row.pid)),
              row: row,
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(
    FlushipThemeExtension ft, {
    required String subtitle,
    required String title,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        AppText.custom(color: color, title, weight: FontWeight.w700),
        AppText.custom(color: ft.colors.textDim, subtitle),
      ],
    ).padOnly(t: ft.spacing.md, b: ft.spacing.sm);
  }

  Future<void> _confirmKillOrphans(
    BuildContext context,
    ProcessManagerBloc bloc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kill all orphan processes?'),
        content: const Text(
          'These processes are leftovers from earlier Fluship runs and are not linked to any active shell.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kill all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(const ProcessManagerKillAllOrphans());
    }
  }

  Future<void> _confirmKill(
    ProcessManagerBloc bloc,
    BuildContext context,
    ProcessRow row,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kill ${row.displayName}?'),
        content: Text(row.kindDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kill'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(ProcessManagerKillProcess(pid: row.pid));
    }
  }
}
