import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger, success }

enum AppButtonSize { sm, md, lg }

@immutable
class const _AppButtonMetrics({
  required final double iconSize,
  required final double fontSize,
  required final double spacing,
  required final EdgeInsets padding,
  required final double height,
}) {
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
class const _AppButtonColors({
  required final Color disabledForeground,
  required final Color disabledBackground,
  required final Color foreground,
  required final Color background,
  required final Color overlay,
  required final Color pressed,
  required final Color hovered,
  required final Color border,
}) {
  static Color _onFilledBackground(Color background) =>
      background.computeLuminance() > 0.55
      ? const Color(0xFF1f2328)
      : const Color(0xFFffffff);

  static _AppButtonColors resolve({
    required AppButtonVariant variant,
    required ThemePalette colors,
  }) {
    return switch (variant) {
      .primary => _AppButtonColors(
        overlay: colors.accent.withValues(alpha: 0.12),
        foreground: _onFilledBackground(colors.accent),
        disabledBackground: colors.disabled,
        disabledForeground: colors.textDim,
        border: Colors.transparent,
        pressed: colors.accentHover,
        hovered: colors.accentHover,
        background: colors.accent,
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
        foreground: _onFilledBackground(colors.danger),
      ),
      .success => _AppButtonColors(
        overlay: colors.success.withValues(alpha: 0.12),
        pressed: colors.success.withValues(alpha: 0.85),
        hovered: colors.success.withValues(alpha: 0.9),
        disabledBackground: colors.disabled,
        disabledForeground: colors.textDim,
        border: Colors.transparent,
        background: colors.success,
        foreground: _onFilledBackground(colors.success),
      ),
    };
  }
}

class AppButton extends StatelessWidget {
  const new({
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

  const new primary({
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

  const new secondary({
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

  const new outline({
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

  const new ghost({
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
  }) : variant = .ghost;

  const new danger({
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
  }) : variant = .danger;

  const new success({
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
  }) : variant = .success;

  const new icon({
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

class const _AppButtonBody({
  required final String? semanticLabel,
  required final bool isIconOnly,
  required final bool autofocus,
  required final FocusNode? focusNode,
  required final VoidCallback? longPress,
  required final bool isEnabled,
  required final bool isLoading,
  required final VoidCallback? onPressed,
  required final Widget? trailing,
  required final Widget? leading,
  required final _AppButtonMetrics metrics,
  required final _AppButtonColors palette,
  required final AppButtonVariant variant,
  required final double radius,
  required final String? label,
}) extends StatelessWidget {
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
      padding: .all(isIconOnly ? .zero : metrics.padding),
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

    final iconTheme = IconThemeData(
      color: isEnabled ? palette.foreground : palette.disabledForeground,
      size: metrics.iconSize,
    );

    if (isIconOnly) {
      return IconTheme(data: iconTheme, child: leading!);
    }

    return Row(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      children: [
        if (leading != null) ...[
          IconTheme(data: iconTheme, child: leading!),
          SizedBox(width: metrics.spacing),
        ],
        if (text != null) Flexible(child: text),
        if (trailing != null) ...[
          SizedBox(width: metrics.spacing),
          IconTheme(data: iconTheme, child: trailing!),
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
