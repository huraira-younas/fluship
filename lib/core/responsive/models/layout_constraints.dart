import 'package:equatable/equatable.dart';

class LayoutConstraints extends Equatable {
  const LayoutConstraints({this.maxWidth = 1080, this.minWidth = 360});

  final double maxWidth;
  final double minWidth;

  static const material3 = LayoutConstraints();

  @override
  List<Object?> get props => [minWidth, maxWidth];
}
