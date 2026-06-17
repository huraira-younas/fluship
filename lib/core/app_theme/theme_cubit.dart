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

  AppTheme get theme => switch (mode) {
    .system => bundle.dark,
    .light => bundle.light,
    .dark => bundle.dark,
  };

  ThemePalette get colors => theme.palette;

  ThemeRadius get radius => theme.radius;

  ThemeSpacing get spacing => theme.spacing;

  ThemeData get lightThemeData => bundle.light.toThemeData(brightness: .light);
  ThemeData get darkThemeData => bundle.dark.toThemeData(brightness: .dark);

  @override
  List<Object?> get props => [preset, mode];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({AppThemes? initial}) : super(_resolveInitial(initial));

  static ThemeState _resolveInitial(AppThemes? initial) {
    ThemePresetRegistry.registerAll();
    final saved = AppThemes.fromKey(SharedPrefs.i.themeMode);

    return ThemeState(preset: saved ?? initial ?? AppThemes.defaultTheme);
  }

  void setTheme(AppThemes theme) {
    if (state.activeTheme == theme) return;
    SharedPrefs.i.setThemeMode(theme.key);
    emit(ThemeState(preset: theme, mode: state.mode));
  }

  void setThemeMode(ThemeMode mode) {
    if (state.mode == mode) return;
    emit(ThemeState(preset: state.preset, mode: mode));
  }
}
