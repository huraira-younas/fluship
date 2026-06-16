import 'package:flutter/material.dart';

import '../fluship_theme_extension.dart';
import '../models/theme.dart';

class AppThemeDataMapper {
  AppThemeDataMapper._();

  static ThemeData toThemeData(AppTheme theme) {
    final colors = theme.palette;

    return ThemeData(
      scaffoldBackgroundColor: colors.bg,
      brightness: .dark,
      colorScheme: ColorScheme.dark(
        surfaceContainerHighest: colors.hover,
        outline: colors.cardBorder,
        secondary: colors.section,
        onSecondary: colors.bg,
        surface: colors.cardBg,
        onSurface: colors.text,
        primary: colors.accent,
        onError: colors.text,
        onPrimary: colors.bg,
        error: colors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.cardBg,
        foregroundColor: colors.text,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(theme.radius.card),
          side: .new(color: colors.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: .auto,
        contentPadding: .symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.md,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          final focused = states.contains(WidgetState.focused);
          return TextStyle(
            color: focused ? colors.accent : colors.section,
            backgroundColor: theme.codeBg,
            fontWeight: .w500,
            fontSize: 12,
          );
        }),
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          final focused = states.contains(WidgetState.focused);
          return TextStyle(
            color: focused ? colors.accent : colors.muted,
            fontWeight: .w400,
            fontSize: 14,
          );
        }),
        hintStyle: TextStyle(
          color: colors.muted,
          fontWeight: .w400,
          fontSize: 14,
        ),
        fillColor: theme.inputBg,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: .circular(theme.radius.input),
          borderSide: .new(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: .circular(theme.radius.input),
          borderSide: .new(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: .circular(theme.radius.input),
          borderSide: .new(color: colors.accent),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: .circular(theme.radius.btn),
          ),
          padding: .symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          backgroundColor: colors.accent,
          foregroundColor: colors.bg,
        ),
      ),
      extensions: [FlushipThemeExtension.fromAppTheme(theme)],
    );
  }
}

extension AppThemeData on AppTheme {
  ThemeData toThemeData() => AppThemeDataMapper.toThemeData(this);
}
