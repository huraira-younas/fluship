import 'package:equatable/equatable.dart';
import 'dart:io' show Platform;

class LayoutConstraints extends Equatable {
  LayoutConstraints({this.minWidth = 360})
    : maxWidth = Platform.isWindows ? 1380 : 1080;

  final double maxWidth;
  final double minWidth;

  static final material3 = LayoutConstraints();

  static const sidePanelFlex = 3;
  static const bodyFlex = 7;

  @override
  List<Object?> get props => [minWidth, maxWidth];
}
