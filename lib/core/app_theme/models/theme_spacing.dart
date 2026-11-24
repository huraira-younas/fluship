part of 'theme.dart';

class const ThemeSpacing({
  final double md = 15,
  final double lg = 20,
  final double sm = 8,
}) extends Equatable {
  @override
  List<Object?> get props => [sm, md, lg];
}
