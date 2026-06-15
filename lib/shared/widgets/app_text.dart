import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/material.dart';

enum AppTextVariant {
  secondary,
  success,
  primary,
  accent,
  danger,
  muted,
  warn,
  code,
  dim,
}

enum AppTextSize { caption, body, subtitle, title, headline, display }

@immutable
class _AppTextMetrics {
  const _AppTextMetrics({
    required this.letterSpacing,
    required this.lineHeight,
    required this.fontSize,
    required this.weight,
  });

  final double letterSpacing;
  final FontWeight weight;
  final double lineHeight;
  final double fontSize;

  static _AppTextMetrics forSize(AppTextSize size) {
    return switch (size) {
      .caption => const _AppTextMetrics(
        letterSpacing: 0.15,
        lineHeight: 1.35,
        weight: .w500,
        fontSize: 12,
      ),
      .body => const _AppTextMetrics(
        letterSpacing: 0.1,
        lineHeight: 1.45,
        weight: .w400,
        fontSize: 14,
      ),
      .subtitle => const _AppTextMetrics(
        letterSpacing: 0.05,
        lineHeight: 1.4,
        weight: .w500,
        fontSize: 16,
      ),
      .title => const _AppTextMetrics(
        letterSpacing: 0,
        lineHeight: 1.35,
        weight: .w600,
        fontSize: 18,
      ),
      .headline => const _AppTextMetrics(
        letterSpacing: -0.2,
        lineHeight: 1.25,
        weight: .w700,
        fontSize: 22,
      ),
      .display => const _AppTextMetrics(
        letterSpacing: -0.4,
        lineHeight: 1.15,
        weight: .w700,
        fontSize: 28,
      ),
    };
  }
}

class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    this.variant = .primary,
    this.selectable = false,
    this.semanticsLabel,
    this.size = .body,
    this.headingLevel,
    this.textAlign,
    this.overflow,
    this.softWrap,
    this.maxLines,
    this.weight,
    super.key,
  }) : assert(
         headingLevel == null || (headingLevel >= 1 && headingLevel <= 3),
         'headingLevel must be between 1 and 3.',
       );

  const AppText.body(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.weight,
    super.key,
  }) : headingLevel = null,
       variant = .primary,
       size = .body;

  const AppText.subtitle(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.weight,
    super.key,
  }) : variant = .secondary,
       headingLevel = null,
       size = .subtitle;

  const AppText.title(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.textAlign,
    this.overflow,
    this.softWrap,
    this.maxLines,
    this.weight,
    super.key,
  }) : headingLevel = null,
       variant = .primary,
       size = .title;

  const AppText.headline(
    this.data, {
    this.selectable = false,
    this.headingLevel = 1,
    this.semanticsLabel,
    this.textAlign,
    this.overflow,
    this.softWrap,
    this.maxLines,
    this.weight,
    super.key,
  }) : variant = .primary,
       size = .headline;

  const AppText.display(
    this.data, {
    this.selectable = false,
    this.headingLevel = 1,
    this.semanticsLabel,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.weight,
    super.key,
  }) : variant = .primary,
       size = .display;

  const AppText.caption(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.variant = .dim,
    this.textAlign,
    this.overflow,
    this.softWrap,
    this.maxLines,
    this.weight,
    super.key,
  }) : headingLevel = null,
       size = .caption;

  const AppText.label(
    this.data, {
    this.selectable = false,
    this.variant = .muted,
    this.semanticsLabel,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.weight,
    super.key,
  }) : headingLevel = null,
       size = .caption;

  const AppText.accent(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.size = .body,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.weight,
    super.key,
  }) : headingLevel = null,
       variant = .accent;

  const AppText.danger(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.size = .body,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.weight,
    super.key,
  }) : headingLevel = null,
       variant = .danger;

  const AppText.success(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.size = .body,
    this.textAlign,
    this.maxLines,
    this.softWrap,
    this.overflow,
    this.weight,
    super.key,
  }) : headingLevel = null,
       variant = .success;

  const AppText.code(
    this.data, {
    this.selectable = false,
    this.semanticsLabel,
    this.size = .body,
    this.textAlign,
    this.maxLines,
    this.softWrap,
    this.overflow,
    this.weight,
    super.key,
  }) : headingLevel = null,
       variant = .code;

  final AppTextVariant variant;
  final TextOverflow? overflow;
  final String? semanticsLabel;
  final TextAlign? textAlign;
  final FontWeight? weight;
  final int? headingLevel;
  final AppTextSize size;
  final bool selectable;
  final bool? softWrap;
  final int? maxLines;
  final String data;

  Color _resolveColor(FlushipThemeExtension theme) {
    if (headingLevel != null) {
      return theme.headingColors[headingLevel!] ?? theme.colors.text;
    }

    final colors = theme.colors;

    return switch (variant) {
      .secondary => colors.section,
      .success => colors.success,
      .accent => colors.accent,
      .danger => colors.danger,
      .primary => colors.text,
      .muted => colors.muted,
      .dim => colors.textDim,
      .warn => colors.warn,
      .code => colors.cmd,
    };
  }

  TextStyle _resolveStyle(FlushipThemeExtension theme) {
    final metrics = _AppTextMetrics.forSize(size);
    final color = _resolveColor(theme);

    return TextStyle(
      fontFeatures: variant == .code ? const [.tabularFigures()] : null,
      fontFamily: variant == .code ? 'monospace' : null,
      letterSpacing: metrics.letterSpacing,
      fontWeight: weight ?? metrics.weight,
      fontSize: metrics.fontSize,
      height: metrics.lineHeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.flushipTheme;
    final style = _resolveStyle(theme);

    final text = selectable
        ? SelectableText(
            data,
            semanticsLabel: semanticsLabel,
            textAlign: textAlign,
            maxLines: maxLines,
            style: style,
          )
        : Text(
            data,
            semanticsLabel: semanticsLabel,
            textAlign: textAlign,
            overflow: overflow,
            maxLines: maxLines,
            softWrap: softWrap,
            style: style,
          );

    return text;
  }
}
