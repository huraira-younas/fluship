import 'package:fluship/core/app_theme/registry/theme_preset_registry.dart';
import 'package:fluship/core/app_theme/registry/app_theme_registry.dart';
import 'package:fluship/core/app_theme/models/app_themes.dart';
import 'package:flutter/material.dart' show Brightness, Color;
import 'package:fluship/core/shared_prefs/shared_prefs.dart';

class ReportHtmlTheme {
  const ReportHtmlTheme({
    required this.cardBorder,
    required this.borderLr,
    required this.bodyOpen,
    required this.success,
    required this.section,
    required this.textDim,
    required this.accent,
    required this.cardBg,
    required this.error,
    required this.text,
    required this.bg,
  });

  static const bodyClose = '</div></body></html>';
  static const flushipVersion = '1.0.0';

  final String cardBorder;
  final String borderLr;
  final String bodyOpen;
  final String success;
  final String section;
  final String textDim;
  final String accent;
  final String cardBg;
  final String error;
  final String text;
  final String bg;

  String get sectionH2Styled =>
      'style="margin:0;font-size:13px;font-weight:700;color:$text;'
      'text-transform:uppercase;letter-spacing:0.6px;"';

  String thStyleAligned(String align) =>
      'style="padding:8px 12px;font-size:11px;font-weight:700;color:$textDim;'
      'text-transform:uppercase;letter-spacing:0.4px;text-align:$align;"';

  static ReportHtmlTheme fromCurrentTheme() {
    ThemePresetRegistry.registerAll();

    final presetKey = SharedPrefs.i.themeMode;
    final preset = AppThemes.fromKey(presetKey) ?? AppThemes.defaultTheme;

    final brightnessStr = SharedPrefs.i.themeBrightness;
    final brightness = brightnessStr == 'light'
        ? Brightness.light
        : Brightness.dark;

    final palette = AppThemeRegistry.get(
      preset,
      brightness: brightness,
    ).palette;

    final cardBorder = _hex(palette.cardBorder);
    final success = _hex(palette.success);
    final section = _hex(palette.section);
    final textDim = _hex(palette.textDim);
    final cardBg = _hex(palette.cardBg);
    final accent = _hex(palette.accent);
    final error = _hex(palette.error);
    final text = _hex(palette.text);
    final bg = _hex(palette.bg);

    return ReportHtmlTheme(
      borderLr:
          'border-left:1px solid $cardBorder;border-right:1px solid $cardBorder;',
      bodyOpen:
          '<!DOCTYPE html><html><head><meta charset="utf-8"></head>'
          '<body style="margin:0;padding:24px 12px;background:$bg;'
          'font-family:Segoe UI,system-ui,sans-serif;">'
          '<div style="max-width:560px;margin:0 auto;">',
      cardBorder: cardBorder,
      success: success,
      section: section,
      textDim: textDim,
      accent: accent,
      cardBg: cardBg,
      error: error,
      text: text,
      bg: bg,
    );
  }

  static String _hex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
}
