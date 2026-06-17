import 'package:fluship/core/app_theme/registry/app_theme_registry.dart';
import 'package:fluship/core/app_theme/theme_cubit.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../widgets/theme_mode_toggle.dart';
import '../widgets/theme_card.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key, required this.spacing});
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();

    return AppCard(
      title: 'Theme',
      description: 'Choose your color palette',
      children: [
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            final themes = AppThemeRegistry.availableThemes;
            final active = state.activeTheme;

            return Column(
              crossAxisAlignment: .stretch,
              spacing: spacing - 4,
              children: [
                const ThemeSectionLabel('Appearance'),
                ThemeGroupBox(
                  child: ThemeModeToggle(
                    onChanged: themeCubit.setThemeMode,
                    mode: state.mode,
                  ),
                ),
                const SizedBox(height: 4),
                const ThemeSectionLabel('Palette'),
                ThemeGroupBox(
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      for (var i = 0; i < themes.length; i++)
                        ThemeCard(
                          onApply: () => themeCubit.setTheme(themes[i]),
                          displayName: themes[i].displayName,
                          showDivider: i < themes.length - 1,
                          isActive: themes[i] == active,
                          theme: AppThemeRegistry.get(
                            brightness: state.brightness,
                            themes[i],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
