import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger, success }

enum AppButtonSize { sm, md, lg }

@immutable
class _AppButtonMetrics {
  const _AppButtonMetrics({
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
    required this.padding,
    required this.height,
  });

  final EdgeInsets padding;
  final double iconSize;
  final double fontSize;
  final double spacing;
  final double height;

  static _AppButtonMetrics forSize(AppButtonSize size, ThemeSpacing pad) {
    return switch (size) {
      .sm => _AppButtonMetrics(
        padding: .symmetric(horizontal: pad.sm + 4, vertical: pad.sm - 2),
        iconSize: 16,
        fontSize: 13,
        spacing: 6,
        height: 36,
      ),
      .md => _AppButtonMetrics(
        padding: .symmetric(horizontal: pad.md, vertical: pad.sm),
        spacing: pad.sm,
        iconSize: 18,
        fontSize: 14,
        height: 40,
      ),
      .lg => _AppButtonMetrics(
        padding: .symmetric(horizontal: pad.lg, vertical: pad.sm + 4),
        spacing: pad.sm + 2,
        iconSize: 20,
        fontSize: 16,
        height: 48,
      ),
    };
  }
}

@immutable
class _AppButtonColors {
  const _AppButtonColors({
    required this.disabledForeground,
    required this.disabledBackground,
    required this.foreground,
    required this.background,
    required this.overlay,
    required this.pressed,
    required this.hovered,
    required this.border,
  });

  final Color disabledForeground;
  final Color disabledBackground;
  final Color foreground;
  final Color background;
  final Color overlay;
  final Color pressed;
  final Color hovered;
  final Color border;

  static _AppButtonColors resolve({
    required AppButtonVariant variant,
    required ThemePalette colors,
  }) {
    return switch (variant) {
      .primary => _AppButtonColors(
        overlay: colors.accent.withValues(alpha: 0.12),
        disabledBackground: colors.disabled,
        disabledForeground: colors.textDim,
        border: Colors.transparent,
        pressed: colors.accentHover,
        hovered: colors.accentHover,
        background: colors.accent,
        foreground: colors.bg,
      ),
      .secondary => _AppButtonColors(
        overlay: colors.hover.withValues(alpha: 0.35),
        disabledBackground: colors.disabled,
        disabledForeground: colors.textDim,
        background: colors.cardBg,
        border: colors.cardBorder,
        foreground: colors.text,
        pressed: colors.hover,
        hovered: colors.hover,
      ),
      .outline => _AppButtonColors(
        overlay: colors.accent.withValues(alpha: 0.08),
        pressed: colors.hover.withValues(alpha: 0.45),
        hovered: colors.hover.withValues(alpha: 0.3),
        disabledBackground: Colors.transparent,
        disabledForeground: colors.textDim,
        background: Colors.transparent,
        border: colors.cardBorder,
        foreground: colors.text,
      ),
      .ghost => _AppButtonColors(
        pressed: colors.accent.withValues(alpha: 0.16),
        hovered: colors.accent.withValues(alpha: 0.08),
        overlay: colors.accent.withValues(alpha: 0.1),
        disabledBackground: Colors.transparent,
        disabledForeground: colors.textDim,
        background: Colors.transparent,
        border: Colors.transparent,
        foreground: colors.accent,
      ),
      .danger => _AppButtonColors(
        overlay: colors.danger.withValues(alpha: 0.12),
        disabledBackground: colors.disabled,
        disabledForeground: colors.textDim,
        border: Colors.transparent,
        pressed: colors.dangerHover,
        hovered: colors.dangerHover,
        background: colors.danger,
        foreground: colors.bg,
      ),
      .success => _AppButtonColors(
        overlay: colors.success.withValues(alpha: 0.12),
        pressed: colors.success.withValues(alpha: 0.85),
        hovered: colors.success.withValues(alpha: 0.9),
        disabledBackground: colors.disabled,
        disabledForeground: colors.textDim,
        border: Colors.transparent,
        background: colors.success,
        foreground: colors.bg,
      ),
    };
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    this.isExpanded = false,
    this.variant = .primary,
    this.isLoading = false,
    this.autofocus = false,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.trailing,
    this.leading,
    this.tooltip,
    this.label,
    super.key,
  }) : assert(
         label != null || leading != null || trailing != null,
         'Provide a label or an icon.',
       );

  const AppButton.primary({
    this.isExpanded = false,
    this.autofocus = false,
    this.isLoading = false,
    required this.label,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.trailing,
    this.tooltip,
    this.leading,
    super.key,
  }) : variant = .primary;

  const AppButton.secondary({
    this.isExpanded = false,
    this.autofocus = false,
    this.isLoading = false,
    required this.label,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.trailing,
    this.leading,
    this.tooltip,
    super.key,
  }) : variant = .secondary;

  const AppButton.outline({
    this.isExpanded = false,
    this.autofocus = false,
    this.isLoading = false,
    required this.label,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.trailing,
    this.tooltip,
    this.leading,
    super.key,
  }) : variant = .outline;

  const AppButton.ghost({
    this.isExpanded = false,
    this.autofocus = false,
    this.isLoading = false,
    required this.label,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.trailing,
    this.tooltip,
    this.leading,
    super.key,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    this.isExpanded = false,
    this.autofocus = false,
    this.isLoading = false,
    required this.label,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.trailing,
    this.tooltip,
    this.leading,
    super.key,
  }) : variant = AppButtonVariant.danger;

  const AppButton.success({
    this.isExpanded = false,
    this.autofocus = false,
    this.isLoading = false,
    required this.label,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.trailing,
    this.tooltip,
    this.leading,
    super.key,
  }) : variant = AppButtonVariant.success;

  const AppButton.icon({
    required Widget this.leading,
    this.isLoading = false,
    this.autofocus = false,
    this.variant = .ghost,
    this.semanticLabel,
    this.onLongPress,
    this.size = .md,
    this.onPressed,
    this.focusNode,
    this.tooltip,
    super.key,
  }) : isExpanded = false,
       trailing = null,
       label = null;

  final VoidCallback? onLongPress;
  final AppButtonVariant variant;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final AppButtonSize size;
  final Widget? trailing;
  final String? tooltip;
  final Widget? leading;
  final bool isExpanded;
  final bool isLoading;
  final bool autofocus;
  final String? label;

  bool get _isEnabled => !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final flushipTheme = context.flushipTheme;
    
    final metrics = _AppButtonMetrics.forSize(size, flushipTheme.spacing);
    final palette = _AppButtonColors.resolve(
      colors: flushipTheme.colors,
      variant: variant,
    );

    final button = _AppButtonBody(
      semanticLabel: semanticLabel ?? label ?? tooltip,
      onPressed: isLoading ? null : onPressed,
      radius: flushipTheme.radius.btn,
      isIconOnly: label == null,
      longPress: onLongPress,
      isEnabled: _isEnabled,
      autofocus: autofocus,
      focusNode: focusNode,
      isLoading: isLoading,
      trailing: trailing,
      leading: leading,
      metrics: metrics,
      variant: variant,
      palette: palette,
      label: label,
    );

    final widthWrapped = isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;

    if (tooltip == null) return widthWrapped;

    return Tooltip(message: tooltip!, child: widthWrapped);
  }
}

class _AppButtonBody extends StatelessWidget {
  const _AppButtonBody({
    required this.semanticLabel,
    required this.isIconOnly,
    required this.autofocus,
    required this.focusNode,
    required this.longPress,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    required this.trailing,
    required this.leading,
    required this.metrics,
    required this.palette,
    required this.variant,
    required this.radius,
    required this.label,
  });

  final _AppButtonMetrics metrics;
  final AppButtonVariant variant;
  final _AppButtonColors palette;
  final VoidCallback? onPressed;
  final VoidCallback? longPress;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final Widget? trailing;
  final Widget? leading;
  final bool isIconOnly;
  final bool isLoading;
  final bool isEnabled;
  final bool autofocus;
  final String? label;
  final double radius;

  ButtonStyle get _style {
    Color resolveForeground(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return palette.disabledForeground;
      }

      return palette.foreground;
    }

    Color resolveBackground(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return palette.disabledBackground;
      }
      if (states.contains(WidgetState.pressed)) {
        return palette.pressed;
      }
      if (states.contains(WidgetState.hovered)) {
        return palette.hovered;
      }

      return palette.background;
    }

    return ButtonStyle(
      maximumSize: isIconOnly
          ? .all(Size(metrics.height, metrics.height))
          : null,
      minimumSize: .all(Size(isIconOnly ? metrics.height : 64, metrics.height)),
      padding: .all(isIconOnly ? EdgeInsets.zero : metrics.padding),
      foregroundColor: .resolveWith(resolveForeground),
      backgroundColor: .resolveWith(resolveBackground),
      shadowColor: .all(Colors.transparent),
      overlayColor: .all(palette.overlay),
      tapTargetSize: .shrinkWrap,
      visualDensity: .standard,
      elevation: .all(0),
      shape: .all(
        RoundedRectangleBorder(
          borderRadius: .circular(radius),
          side: BorderSide(
            color: isEnabled
                ? palette.border
                : palette.disabledForeground.withValues(alpha: 0.35),
          ),
        ),
      ),
      textStyle: .all(
        TextStyle(
          fontSize: metrics.fontSize,
          letterSpacing: 0.2,
          fontWeight: .w600,
        ),
      ),
      iconSize: .all(metrics.iconSize),
      mouseCursor: .resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }

        return SystemMouseCursors.click;
      }),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        height: metrics.iconSize,
        width: metrics.iconSize,
        child: CircularProgressIndicator(
          color: palette.foreground,
          strokeWidth: 2,
        ),
      );
    }

    final text = label == null
        ? null
        : Text(overflow: .ellipsis, textAlign: .center, maxLines: 1, label!);

    if (isIconOnly) {
      return IconTheme(
        data: IconThemeData(size: metrics.iconSize),
        child: leading!,
      );
    }

    return Row(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      children: [
        if (leading != null) ...[
          IconTheme(
            data: IconThemeData(size: metrics.iconSize),
            child: leading!,
          ),
          SizedBox(width: metrics.spacing),
        ],
        if (text != null) Flexible(child: text),
        if (trailing != null) ...[
          SizedBox(width: metrics.spacing),
          IconTheme(
            data: IconThemeData(size: metrics.iconSize),
            child: trailing!,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();

    final button = switch (variant) {
      .outline => OutlinedButton(
        onLongPress: longPress,
        autofocus: autofocus,
        focusNode: focusNode,
        onPressed: onPressed,
        style: _style,
        child: child,
      ),
      .ghost => TextButton(
        onLongPress: longPress,
        autofocus: autofocus,
        focusNode: focusNode,
        onPressed: onPressed,
        style: _style,
        child: child,
      ),
      _ => ElevatedButton(
        onLongPress: longPress,
        onPressed: onPressed,
        autofocus: autofocus,
        focusNode: focusNode,
        style: _style,
        child: child,
      ),
    };

    return Semantics(
      label: semanticLabel,
      enabled: isEnabled,
      button: true,
      child: button,
    );
  }
}
