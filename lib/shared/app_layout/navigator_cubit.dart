import 'package:flutter_bloc/flutter_bloc.dart';

enum LayoutTabs {
  config(0),
  console(1),
  settings(2);

  const LayoutTabs(this.value);
  final int value;

  static LayoutTabs fromValue(int value) =>
      values.firstWhere((e) => e.value == value);
}

class NavigatorCubit extends Cubit<LayoutTabs> {
  NavigatorCubit() : super(.config);

  void navigate(LayoutTabs value) => emit(value);
}
