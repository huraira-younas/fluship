import 'package:material_ui/material_ui.dart';

import 'models/theme.dart';

@immutable
class const FlushipThemeExtension({
  required final Map<int, Color> headingColors,
  required final Color codeBorder,
  required final ThemeSpacing spacing,
  required final Color codeBg,
  required final ThemePalette colors,
  required final ThemeRadius radius,
  required final AppTheme theme,
}) extends ThemeExtension<FlushipThemeExtension> {
  factory fromAppTheme(AppTheme theme) {
    return FlushipThemeExtension(
      headingColors: theme.headingColors,
      codeBorder: theme.codeBorder,
      spacing: theme.spacing,
      colors: theme.palette,
      radius: theme.radius,
      codeBg: theme.codeBg,
      theme: theme,
    );
  }

  @override
  FlushipThemeExtension copyWith({
    Map<int, Color>? headingColors,
    ThemeSpacing? spacing,
    ThemePalette? colors,
    ThemeRadius? radius,
    Color? codeBorder,
    AppTheme? theme,
    Color? codeBg,
  }) {
    return FlushipThemeExtension(
      headingColors: headingColors ?? this.headingColors,
      codeBorder: codeBorder ?? this.codeBorder,
      spacing: spacing ?? this.spacing,
      codeBg: codeBg ?? this.codeBg,
      colors: colors ?? this.colors,
      radius: radius ?? this.radius,
      theme: theme ?? this.theme,
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
