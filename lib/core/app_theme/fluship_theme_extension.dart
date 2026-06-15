import 'package:flutter/material.dart';
import 'models/theme.dart';

@immutable
class FlushipThemeExtension extends ThemeExtension<FlushipThemeExtension> {
  const FlushipThemeExtension({
    required this.headingColors,
    required this.codeBorder,
    required this.codeBg,
    required this.colors,
    required this.radius,
    required this.theme,
    required this.pad,
  });

  final Map<int, Color> headingColors;
  final ThemePalette colors;
  final ThemeRadius radius;
  final ThemeSpacing pad;
  final Color codeBorder;
  final AppTheme theme;
  final Color codeBg;

  factory FlushipThemeExtension.fromAppTheme(AppTheme theme) {
    return FlushipThemeExtension(
      headingColors: theme.headingColors,
      codeBorder: theme.codeBorder,
      colors: theme.palette,
      radius: theme.radius,
      codeBg: theme.codeBg,
      pad: theme.pad,
      theme: theme,
    );
  }

  @override
  FlushipThemeExtension copyWith({
    Map<int, Color>? headingColors,
    ThemePalette? colors,
    ThemeRadius? radius,
    Color? codeBorder,
    ThemeSpacing? pad,
    AppTheme? theme,
    Color? codeBg,
  }) {
    return FlushipThemeExtension(
      headingColors: headingColors ?? this.headingColors,
      codeBorder: codeBorder ?? this.codeBorder,
      codeBg: codeBg ?? this.codeBg,
      colors: colors ?? this.colors,
      radius: radius ?? this.radius,
      theme: theme ?? this.theme,
      pad: pad ?? this.pad,
    );
  }

  @override
  FlushipThemeExtension lerp(
    ThemeExtension<FlushipThemeExtension>? other,
    double t,
  ) {
    return this;
  }
}

extension FlushipThemeContext on BuildContext {
  FlushipThemeExtension get flushipTheme {
    final extension = Theme.of(this).extension<FlushipThemeExtension>();
    assert(
      extension != null,
      'FlushipThemeExtension not found. Ensure AppTheme.toThemeData() is used.',
    );
    return extension!;
  }
}
