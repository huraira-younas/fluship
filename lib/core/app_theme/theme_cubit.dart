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
  const ThemeState({required this.theme});

  final AppTheme theme;

  AppThemes get activeTheme => theme.id;

  ThemePalette get colors => theme.palette;

  ThemeRadius get radius => theme.radius;

  ThemeSpacing get spacing => theme.spacing;

  ThemeData get themeData => theme.toThemeData();

  @override
  List<Object?> get props => [theme];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({AppThemes? initial}) : super(_resolveInitial(initial));

  static ThemeState _resolveInitial(AppThemes? initial) {
    ThemePresetRegistry.registerAll();
    final saved = AppThemes.fromKey(SharedPrefs.i.themeMode);

    return ThemeState(
      theme: AppThemeRegistry.get(
        saved ?? initial ?? AppThemes.defaultTheme,
      ),
    );
  }

  void setTheme(AppThemes theme) {
    if (state.activeTheme == theme) return;
    SharedPrefs.i.setThemeMode(theme.key);
    emit(ThemeState(theme: AppThemeRegistry.get(theme)));
  }
}
