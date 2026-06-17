import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:fluship/core/shared_prefs/shared_prefs.dart';

import 'registry/theme_preset_registry.dart';
import 'mappers/app_theme_data_mapper.dart';
import 'registry/app_theme_registry.dart';
import 'models/app_themes.dart';
import 'models/theme.dart';

class ThemeState extends Equatable {
  const ThemeState({this.mode = .dark, required this.preset});

  final AppThemes preset;
  final ThemeMode mode;

  ThemePresetBundle get bundle => AppThemeRegistry.getBundle(preset);

  AppThemes get activeTheme => preset;

  Brightness get brightness => switch (mode) {
    .system => .dark,
    .light => .light,
    .dark => .dark,
  };

  AppTheme get theme {
    return switch (mode) {
      .system => bundle.dark,
      .light => bundle.light,
      .dark => bundle.dark,
    };
  }

  ThemeSpacing get spacing => theme.spacing;
  ThemePalette get colors => theme.palette;
  ThemeRadius get radius => theme.radius;

  ThemeData get lightThemeData => bundle.light.toThemeData(brightness: .light);
  ThemeData get darkThemeData => bundle.dark.toThemeData(brightness: .dark);

  @override
  List<Object?> get props => [preset, mode];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({AppThemes? initial}) : super(_resolveInitial(initial));

  static ThemeState _resolveInitial(AppThemes? initial) {
    ThemePresetRegistry.registerAll();

    final savedPreset = AppThemes.fromKey(SharedPrefs.i.themeMode);
    final savedMode = _parseMode(SharedPrefs.i.themeBrightness);

    return ThemeState(
      preset: savedPreset ?? initial ?? .defaultTheme,
      mode: savedMode,
    );
  }

  static ThemeMode _parseMode(String value) => switch (value) {
    'light' => .light,
    _ => .dark,
  };

  static String _modeKey(ThemeMode mode) => mode == .light ? 'light' : 'dark';

  void setTheme(AppThemes theme) {
    if (state.activeTheme == theme) return;
    SharedPrefs.i.setThemeMode(theme.key);
    emit(ThemeState(preset: theme, mode: state.mode));
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == ThemeMode.system || state.mode == mode) return;
    SharedPrefs.i.setThemeBrightness(_modeKey(mode));
    emit(ThemeState(preset: state.preset, mode: mode));
  }
}
