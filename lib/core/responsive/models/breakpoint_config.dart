import 'package:equatable/equatable.dart';

class BreakpointConfig extends Equatable {
  const BreakpointConfig({
    this.expandedMax = 1199,
    this.compactMax = 599,
    this.mediumMax = 839,
    this.largeMax = 1599,
  });

  final double expandedMax;
  final double compactMax;
  final double mediumMax;
  final double largeMax;

  const factory BreakpointConfig.material3() = BreakpointConfig;

  @override
  List<Object?> get props => [compactMax, mediumMax, expandedMax, largeMax];
}
