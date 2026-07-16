import 'package:fluship/features/process_manager/views/process_manager_screen.dart';
import 'package:fluship/features/pipeline/widgets/pipeline_runner_panel.dart';
import 'package:fluship/features/file_manager/views/file_manager_screen.dart';
import 'package:fluship/core/responsive/models/layout_constraints.dart';
import 'package:fluship/features/settings/views/settings_screen.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/console/views/console_screen.dart';
import 'package:fluship/core/responsive/responsive_extension.dart';
import 'package:fluship/features/config/views/config_screen.dart';
import 'package:fluship/shared/app_layout/navigator_cubit.dart';
import 'package:fluship/shared/app_layout/developer_card.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../extensions/widget_extensions.dart';
import '../widgets/app_text.dart';
import 'layout_top_builder.dart';

class LayoutScreen extends StatefulWidget {
  const LayoutScreen({super.key});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  Widget _tabFor(LayoutTabs tab) => switch (tab) {
    .processes => const ProcessManagerScreen(),
    .settings => const SettingsScreen(),
    .files => const FileManagerScreen(),
    .console => const ConsoleScreen(),
    .config => const ConfigScreen(),
  };

  @override
  Widget build(BuildContext ctx) {
    final w = LayoutConstraints.material3;
    final ft = ctx.flushipTheme;

    final state = context.watch<NavigatorCubit>().state;
    final content = _buildContent(ctx, ft.spacing, state);

    return Scaffold(
      body: LayoutBuilder(
        builder: (_, constraints) {
          final viewportWidth = constraints.maxWidth;

          if (viewportWidth.isFinite && viewportWidth < w.minWidth) {
            return const AppText.danger(
              "Anni Diya Kitna Chota krega?",
            ).center();
          }

          if (viewportWidth.isFinite && viewportWidth > w.maxWidth) {
            return Container(
              constraints: BoxConstraints(maxWidth: w.maxWidth),
              margin: .all(ft.spacing.md),
              decoration: BoxDecoration(
                border: .all(color: ft.colors.cardBorder),
                borderRadius: .circular(ft.radius.card),
              ),
              child: content,
            ).align(align: .center);
          }

          return content;
        },
      ),
    );
  }

  bool _usesExpandedBody(LayoutTabs tab) =>
      tab == .console || tab == .files || tab == .processes;

  Widget _buildTabBody({required LayoutTabs state, required double hPad}) {
    final key = ValueKey(state.value);
    final tab = _tabFor(state);

    final body = !_usesExpandedBody(state)
        ? SingleChildScrollView(padding: .all(hPad), child: tab)
        : state != .console
        ? tab.padAll(hPad)
        : tab;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: key, child: body),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeSpacing spacing,
    LayoutTabs state,
  ) {
    final isTablet = context.isTabletOrMobile;
    final hPad = isTablet ? spacing.md : spacing.lg;
    final topPad = isTablet ? MediaQuery.paddingOf(context).top : spacing.lg;

    if (isTablet) {
      return Column(
        spacing: spacing.sm,
        children: [
          LayoutTopBuilder(
            selectedTab: state,
            spacing: spacing,
          ).padOnly(l: hPad, r: hPad),
          _buildTabBody(state: state, hPad: hPad).expanded(),
          const DeveloperCard().padSym(h: hPad),
        ],
      ).padOnly(t: topPad, b: spacing.lg);
    }

    final ft = context.flushipTheme;

    return Column(
      spacing: spacing.sm,
      children: [
        Row(
          crossAxisAlignment: .stretch,
          children: [
            Container(
              height: double.infinity,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: ft.colors.codeBorder)),
                color: ft.colors.codeBg,
              ),
              child: Column(
                children: <Widget>[
                  SingleChildScrollView(
                    padding: .all(hPad),
                    child: LayoutTopBuilder(
                      selectedTab: state,
                      spacing: spacing,
                      sidePanel: true,
                    ),
                  ).expanded(),
                  const DeveloperCard().padOnly(
                    l: spacing.sm,
                    r: spacing.sm,
                    b: spacing.sm,
                  ),
                ],
              ),
            ).expanded(flex: LayoutConstraints.sidePanelFlex),
            _buildTabBody(
              state: state,
              hPad: hPad,
            ).expanded(flex: LayoutConstraints.bodyFlex),
            if (context.isDesktop)
              Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: ft.colors.codeBorder)),
                ),
                child: const PipelineRunnerPanel(),
              ).expanded(flex: LayoutConstraints.pipeLineFlex),
          ],
        ).expanded(),
      ],
    );
  }
}
