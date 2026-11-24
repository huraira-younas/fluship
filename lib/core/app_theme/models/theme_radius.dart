part of 'theme.dart';

class const ThemeRadius({
  final double card = 12,
  final double input = 8,
  final double btn = 10,
}) extends Equatable {
  @override
  List<Object?> get props => [input, card, btn];
}
