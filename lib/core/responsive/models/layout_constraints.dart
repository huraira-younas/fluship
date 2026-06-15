import 'package:equatable/equatable.dart';

class LayoutConstraints extends Equatable {
  const LayoutConstraints({
    this.maxDesktopWidth = 1200,
    this.minMobileWidth = 360,
  });

  final double maxDesktopWidth;
  final double minMobileWidth;

  static const material3 = LayoutConstraints();

  @override
  List<Object?> get props => [minMobileWidth, maxDesktopWidth];
}
