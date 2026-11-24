import 'package:equatable/equatable.dart';

class const LayoutConstraints({final double minWidth = 360}) extends Equatable {
  this : maxWidth = .infinity;

  final double maxWidth;

  static final material3 = const LayoutConstraints();

  static const sidePanelFlex = 3;
  static const pipeLineFlex = 5;
  static const bodyFlex = 8;

  @override
  List<Object?> get props => [minWidth, maxWidth];
}
