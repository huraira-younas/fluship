part of 'theme.dart';

class ThemePalette extends Equatable {
  const ThemePalette({
    required this.consoleBorder,
    required this.consoleInner,
    required this.accentHover,
    required this.dangerHover,
    required this.cardBorder,
    required this.consoleBg,
    required this.disabled,
    required this.textDim,
    required this.section,
    required this.success,
    required this.cardBg,
    required this.accent,
    required this.danger,
    required this.error,
    required this.hover,
    required this.muted,
    required this.text,
    required this.warn,
    required this.cmd,
    required this.bg,
  });

  final Color consoleBorder;
  final Color consoleInner;
  final Color accentHover;
  final Color dangerHover;
  final Color cardBorder;
  final Color consoleBg;
  final Color disabled;
  final Color textDim;
  final Color section;
  final Color success;
  final Color cardBg;
  final Color accent;
  final Color danger;
  final Color error;
  final Color hover;
  final Color muted;
  final Color text;
  final Color warn;
  final Color cmd;
  final Color bg;

  Color get codeBorder => consoleBorder;
  Color get codeBg => consoleInner;

  List<Color> get previewSwatches => [
    section,
    success,
    accent,
    cardBg,
    danger,
    warn,
    bg,
  ];

  @override
  List<Object?> get props => [
    consoleBorder,
    consoleInner,
    accentHover,
    dangerHover,
    cardBorder,
    consoleBg,
    disabled,
    textDim,
    section,
    success,
    cardBg,
    accent,
    danger,
    error,
    hover,
    muted,
    text,
    warn,
    cmd,
    bg,
  ];
}
