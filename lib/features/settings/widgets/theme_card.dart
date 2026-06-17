import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/app_theme/mappers/app_theme_data_mapper.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/core/responsive/responsive_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

import 'theme_preview_box.dart';
import 'theme_swatch_row.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    required this.onApply,
    required this.isActive,
    required this.theme,
    super.key,
  });

  final VoidCallback onApply;
  final AppTheme theme;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final palette = theme.palette;
    final displayName = theme.id.displayName;

    final padding = context.responsiveValue(
      compact: ft.spacing.sm,
      medium: ft.spacing.md,
      large: ft.spacing.lg,
    );
    final titleSize = context.responsiveValue(
      compact: AppTextSize.body,
      medium: AppTextSize.subtitle,
      large: AppTextSize.subtitle,
    );
    final previewTextSize = context.responsiveValue(
      compact: AppTextSize.caption,
      medium: AppTextSize.body,
      large: AppTextSize.body,
    );
    final previewMinHeight = context.responsiveValue(
      compact: 48.0,
      medium: 52.0,
      large: 56.0,
    );
    final swatchGap = context.isMobile ? ft.spacing.sm : ft.spacing.sm + 2;
    final buttonSize = context.isMobile ? AppButtonSize.md : AppButtonSize.sm;
    final expandButton = context.isMobile;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? ft.colors.accent : ft.colors.cardBorder,
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(ft.radius.card),
        color: ft.colors.codeBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ft.spacing.sm,
        children: [
          Row(
            children: [
              AppText(
                displayName,
                size: titleSize,
                weight: FontWeight.w600,
              ).expanded(),
              if (isActive)
                const AppText.success('Active', size: AppTextSize.caption),
            ],
          ),
          ThemeSwatchRow(
            palette: palette,
            radius: theme.radius.input,
            gap: swatchGap,
          ),
          ThemePreviewBox(
            displayName: displayName,
            textSize: previewTextSize,
            minHeight: previewMinHeight,
            radius: theme.radius.input,
            palette: palette,
          ),
          if (!isActive)
            Theme(
              data: theme.toThemeData(),
              child: expandButton
                  ? AppButton.primary(
                      onPressed: onApply,
                      isExpanded: true,
                      label: 'Apply',
                      size: buttonSize,
                    )
                  : AppButton.primary(
                      onPressed: onApply,
                      label: 'Apply',
                      size: buttonSize,
                    ).align(align: Alignment.centerRight),
            ),
        ],
      ),
    );
  }
}
