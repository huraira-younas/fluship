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
    required this.spacing,
    super.key,
  });

  final LayoutTabs selectedTab;
  final ThemeSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final pipeline = BlocSelector<PipelineBloc, PipelineState, bool>(
      selector: (state) => state.isRunning,
      builder: (context, isRunning) {
        return AppButton.primary(
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

    final fileManager = AppButton.icon(
      onPressed: () => FileManagerRoutes.openFileManager(),
      leading: const Icon(Icons.folder),
      variant: .outline,
    );

    return Column(
      spacing: spacing.lg,
      children: <Widget>[
        BlocSelector<ConfigBloc, ConfigState, AppInfoModel>(
          selector: (state) => state.appInfo,
          builder: (context, appInfo) {
            return ResponsiveBuilder(
              builder: (context, info) {
                final isMobile = info.isMobile;
                final header = <Widget>[
                  if (isMobile)
                    AppText.display(appInfo.appName ?? 'Fluship')
                  else
                    AppText.display(appInfo.appName ?? 'Fluship').expanded(),
                  Row(
                    spacing: spacing.md,
                    children: [
                      if (isMobile) pipeline.expanded() else pipeline,
                      fileManager,
                    ],
                  ),
                ];

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: .stretch,
                    spacing: spacing.md,
                    children: header,
                  );
                }

                return Row(spacing: spacing.md, children: header);
              },
            );
          },
        ),
        AppTabs(
          contentPadding: .symmetric(
            horizontal: spacing.lg + 10,
            vertical: spacing.sm,
          ),
          onChange: (tab) => context.read<NavigatorCubit>().navigate(tab),
          labels: LayoutTabs.values,
          label: selectedTab,
        ),
      ],
    );
  }
}
