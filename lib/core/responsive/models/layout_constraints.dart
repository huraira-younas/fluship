import 'package:equatable/equatable.dart';

class LayoutConstraints extends Equatable {
  const LayoutConstraints({this.minWidth = 360}) : maxWidth = .infinity;

  final double maxWidth;
  final double minWidth;

  static final material3 = const LayoutConstraints();

  static const sidePanelFlex = 3;
  static const pipeLineFlex = 5;
  static const bodyFlex = 8;

  @override
  List<Object?> get props => [minWidth, maxWidth];
}
