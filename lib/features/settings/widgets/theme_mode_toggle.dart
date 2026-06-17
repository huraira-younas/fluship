import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/material.dart';

class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({
    required this.onChanged,
    required this.mode,
    super.key,
  });

  final ValueChanged<ThemeMode> onChanged;
  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final isDark = mode != .light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDark ? ft.colors.accent : ft.colors.warn,
              key: ValueKey(isDark),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 2,
              children: [
                Text(
                  'Dark mode',
                  style: TextStyle(
                    color: ft.colors.text,
                    letterSpacing: -0.2,
                    fontWeight: .w600,
                    fontSize: 15,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    isDark ? 'Dark appearance' : 'Light appearance',
                    key: ValueKey(isDark),
                    style: TextStyle(
                      color: ft.colors.muted,
                      fontWeight: .w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              onChanged(value ? .dark : .light);
            },
            activeTrackColor: ft.colors.accent.withValues(alpha: 0.4),
            activeThumbColor: ft.colors.accent,
          ),
        ],
      ),
    );
  }
}

class ThemeGroupBox extends StatelessWidget {
  const ThemeGroupBox({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ft.colors.cardBg.withValues(alpha: 0.35),
        borderRadius: .circular(ft.radius.card - 2),
        border: .all(color: ft.colors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: .circular(ft.radius.card - 2),
        child: child,
      ),
    );
  }
}

class ThemeSectionLabel extends StatelessWidget {
  const ThemeSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Padding(
      padding: const .only(left: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: ft.colors.muted,
          letterSpacing: 0.8,
          fontWeight: .w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
