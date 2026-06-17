import 'package:fluship/core/app_theme/registry/app_theme_registry.dart';
import 'package:fluship/core/app_theme/models/app_themes.dart';
import 'package:fluship/core/app_theme/theme_cubit.dart';
import 'package:fluship/core/responsive/responsive.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../widgets/theme_card.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key, required this.spacing});
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Theme',
      description: 'Select a theme for your app',
      children: [
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return ResponsiveBuilder(
              builder: (context, info) {
                final active = state.activeTheme;
                final themes = AppThemeRegistry.availableThemes;
                final themeCubit = context.read<ThemeCubit>();

                ThemeCard buildCard(AppThemes id) => ThemeCard(
                  onApply: () => themeCubit.setTheme(id),
                  theme: AppThemeRegistry.get(id),
                  isMobile: info.isMobile,
                  isActive: id == active,
                );

                if (info.isMobile) {
                  return Column(
                    spacing: spacing,
                    children: themes.map(buildCard).toList(),
                  );
                }

                final columns = context.responsiveValue(
                  compact: 1,
                  medium: 2,
                  large: 3,
                );

                final cardHeight = context.responsiveValue(
                  compact: 200.0,
                  medium: 190.0,
                  large: 200.0,
                );

                return GridView.builder(
                  shrinkWrap: true,
                  itemCount: themes.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, index) => buildCard(themes[index]),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisExtent: cardHeight,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    crossAxisCount: columns,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
