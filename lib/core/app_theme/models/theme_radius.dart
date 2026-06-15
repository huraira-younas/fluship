part of 'theme.dart';

class ThemeRadius extends Equatable {
  const ThemeRadius({this.card = 12, this.input = 8, this.btn = 10});

  final double input;
  final double card;
  final double btn;

  @override
  List<Object?> get props => [input, card, btn];
}
