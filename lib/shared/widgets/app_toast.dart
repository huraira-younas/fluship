import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:toastification/toastification.dart';
import 'package:fluship/core/navigator.dart';
import 'package:flutter/material.dart';

abstract final class AppToast {
  AppToast._();

  static void info(
    String message, {
    String? title,
    Duration autoCloseDuration = const Duration(seconds: 4),
  }) => _show(
    autoCloseDuration: autoCloseDuration,
    message: message,
    title: title,
    type: .info,
  );

  static void success(
    String message, {
    String? title,
    Duration autoCloseDuration = const Duration(seconds: 4),
  }) => _show(
    autoCloseDuration: autoCloseDuration,
    message: message,
    type: .success,
    title: title,
  );

  static void warning(
    String message, {
    String? title,
    Duration autoCloseDuration = const Duration(seconds: 4),
  }) => _show(
    autoCloseDuration: autoCloseDuration,
    message: message,
    type: .warning,
    title: title,
  );

  static void error(
    String message, {
    String? title,
    Duration autoCloseDuration = const Duration(seconds: 5),
  }) => _show(
    autoCloseDuration: autoCloseDuration,
    message: message,
    type: .error,
    title: title,
  );

  static void dismissAll({bool delayForAnimation = true}) {
    toastification.dismissAll(delayForAnimation: delayForAnimation);
  }

  static void _show({
    required Duration autoCloseDuration,
    required ToastificationType type,
    required String message,
    String? title,
  }) {
    final context = appNavigatorKey.currentContext;
    final overlay = appNavigatorKey.currentState?.overlay;

    if (context == null && overlay == null) return;

    final theme = context != null
        ? Theme.of(context).extension<FlushipThemeExtension>()
        : null;
    final colors = theme?.colors;
    final accent = _accentColor(type, colors);

    toastification.show(
      boxShadow: [
        BoxShadow(
          color: (colors?.bg ?? Colors.black).withValues(alpha: 0.45),
          offset: const Offset(0, 6),
          blurRadius: 20,
        ),
      ],
      borderSide: BorderSide(color: colors?.cardBorder ?? Colors.white24),
      borderRadius: BorderRadius.circular(theme?.radius.card ?? 12),
      style: ToastificationStyle.minimal,
      autoCloseDuration: autoCloseDuration,
      backgroundColor: colors?.cardBg,
      foregroundColor: colors?.text,
      description: Text(message),
      primaryColor: accent,
      overlayState: overlay,
      pauseOnHover: true,
      dragToClose: true,
      title: title != null ? Text(title) : null,
      context: context,
      type: type,
    );
  }

  static Color? _accentColor(ToastificationType type, ThemePalette? colors) {
    if (colors == null) return null;

    if (type == ToastificationType.success) return colors.success;
    if (type == ToastificationType.warning) return colors.warn;
    if (type == ToastificationType.error) return colors.danger;
    if (type == ToastificationType.info) return colors.accent;

    return null;
  }
}
