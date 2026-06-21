import 'package:flutter/material.dart' show IconData, Icons;
import 'package:flutter_bloc/flutter_bloc.dart';

enum LayoutTabs {
  config(0),
  console(1),
  settings(2),
  files(3);

  const LayoutTabs(this.value);
  final int value;

  static const mobileNav = [config, console, settings];
  static const desktopNav = LayoutTabs.values;

  static LayoutTabs fromValue(int value) =>
      values.firstWhere((e) => e.value == value);

  String get label => switch (this) {
    .settings => 'Settings',
    .console => 'Console',
    .config => 'Config',
    .files => 'Files',
  };

  IconData get icon => switch (this) {
    .settings => Icons.settings_rounded,
    .console => Icons.terminal_rounded,
    .files => Icons.folder_outlined,
    .config => Icons.tune_rounded,
  };
}

class NavigatorCubit extends Cubit<LayoutTabs> {
  NavigatorCubit() : super(.config);

  void navigate(LayoutTabs value) => emit(value);
}
