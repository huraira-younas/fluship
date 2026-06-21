import 'package:fluship/features/pipeline/bloc/pipeline_bloc.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/features/file_manager/routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/core/responsive/responsive.dart';

import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_tabs.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'navigator_cubit.dart';

class LayoutTopBuilder extends StatelessWidget {
  const LayoutTopBuilder({
    required this.selectedTab,
    this.sidePanel = false,
    required this.spacing,
    super.key,
  });

  final LayoutTabs selectedTab;
  final ThemeSpacing spacing;
  final bool sidePanel;

  @override
  Widget build(BuildContext context) {
    final pipeline = BlocSelector<PipelineBloc, PipelineState, bool>(
      selector: (state) => state.isRunning,
      builder: (context, isRunning) {
        return AppButton.primary(
          isExpanded: sidePanel,
          isLoading: isRunning,
          onPressed: isRunning
              ? null
              : () {
                  getIt<PipelineBloc>().add(const RunPipeline());
                  context.read<NavigatorCubit>().navigate(.console);
                },
          label: isRunning ? 'Running…' : 'Run Pipeline',
        );
      },
    );

    final fileManager = sidePanel
        ? SizedBox(
            width: double.infinity,
            child: AppButton.icon(
              onPressed: () => FileManagerRoutes.openFileManager(),
              leading: const Icon(Icons.folder),
              variant: .outline,
            ),
          )
        : AppButton.icon(
            onPressed: () => FileManagerRoutes.openFileManager(),
            leading: const Icon(Icons.folder),
            variant: .outline,
          );

    final tabPadding = EdgeInsets.symmetric(
      horizontal: spacing.lg + 10,
      vertical: spacing.sm,
    );

    final tabs = sidePanel
        ? AppTabTiles(
            onChange: (tab) => context.read<NavigatorCubit>().navigate(tab),
            contentPadding: tabPadding,
            labels: LayoutTabs.values,
            label: selectedTab,
          )
        : AppTabs(
            onChange: (tab) => context.read<NavigatorCubit>().navigate(tab),
            contentPadding: tabPadding,
            labels: LayoutTabs.values,
            label: selectedTab,
          );

    return BlocSelector<ConfigBloc, ConfigState, AppInfoModel>(
      selector: (state) => state.appInfo,
      builder: (context, appInfo) {
        if (sidePanel) {
          return Column(
            crossAxisAlignment: .stretch,
            spacing: spacing.lg,
            children: [
              AppText.display(appInfo.appName ?? 'Fluship'),
              pipeline,
              fileManager,
              tabs,
            ],
          );
        }

        return ResponsiveBuilder(
          builder: (context, info) {
            final isTablet = info.isTabletOrMobile;
            final header = <Widget>[
              if (isTablet)
                AppText.display(appInfo.appName ?? 'Fluship')
              else
                AppText.display(appInfo.appName ?? 'Fluship').expanded(),
              Row(
                spacing: spacing.md,
                children: [
                  if (isTablet) pipeline.expanded() else pipeline,
                  fileManager,
                ],
              ),
            ];

            return Column(
              crossAxisAlignment: .stretch,
              spacing: spacing.lg,
              children: [
                if (isTablet)
                  Column(
                    crossAxisAlignment: .stretch,
                    spacing: spacing.md,
                    children: header,
                  )
                else
                  Row(spacing: spacing.md, children: header),
                tabs,
              ],
            );
          },
        );
      },
    );
  }
}
