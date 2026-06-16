import 'package:fluship/core/responsive/models/layout_constraints.dart';
import 'package:fluship/features/settings/views/settings_screen.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/console/views/console_screen.dart';
import 'package:fluship/core/responsive/responsive_extension.dart';
import 'package:fluship/features/config/views/config_screen.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
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
  LayoutTabs _selectedTab = LayoutTabs.config;

  final List<Widget> _tabs = [
    const ConfigScreen(),
    const ConsoleScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext ctx) {
    final w = LayoutConstraints.material3;
    final ft = ctx.flushipTheme;

    final content = _buildContent(ctx, ft.spacing);

    return Scaffold(
      body: LayoutBuilder(
        builder: (_, constraints) {
          final viewportWidth = constraints.maxWidth;

          if (viewportWidth.isFinite && viewportWidth < w.minWidth) {
            return AppText.danger("Anni Diya Kitna Chota krega?").center();
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

  Widget _buildContent(BuildContext context, ThemeSpacing spacing) {
    return Column(
      spacing: spacing.sm,
      children: [
        LayoutTopBuilder(
          onTabChanged: (tab) => setState(() => _selectedTab = tab),
          selectedTab: _selectedTab,
          spacing: spacing,
        ),
        SingleChildScrollView(
          padding: .symmetric(vertical: spacing.md),
          child: _tabs[_selectedTab.value],
        ).expanded(),
      ],
    ).padOnly(
      t: context.isMobile ? MediaQuery.paddingOf(context).top : spacing.md,
      l: spacing.md,
      r: spacing.md,
      b: spacing.md,
    );
  }
}
