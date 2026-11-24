import 'package:equatable/equatable.dart';

class const BreakpointConfig({
  final double expandedMax = 1199,
  final double compactMax = 599,
  final double mediumMax = 839,
  final double largeMax = 1599,
}) extends Equatable {
  const factory material3() = BreakpointConfig;

  @override
  List<Object?> get props => [compactMax, mediumMax, expandedMax, largeMax];
}
