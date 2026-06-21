import 'package:equatable/equatable.dart';

class LayoutConstraints extends Equatable {
  const LayoutConstraints({this.maxWidth = 1080, this.minWidth = 360});

  final double maxWidth;
  final double minWidth;

  static const material3 = LayoutConstraints();

  static const sidePanelFlex = 3;
  static const bodyFlex = 7;

  @override
  List<Object?> get props => [minWidth, maxWidth];
}
