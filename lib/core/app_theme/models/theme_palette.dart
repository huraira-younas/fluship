part of 'theme.dart';

class const ThemePalette({
  required final Color consoleBorder,
  required final Color consoleInner,
  required final Color accentHover,
  required final Color dangerHover,
  required final Color cardBorder,
  required final Color consoleBg,
  required final Color disabled,
  required final Color textDim,
  required final Color section,
  required final Color success,
  required final Color cardBg,
  required final Color accent,
  required final Color danger,
  required final Color error,
  required final Color hover,
  required final Color muted,
  required final Color text,
  required final Color warn,
  required final Color cmd,
  required final Color bg,
}) extends Equatable {
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
