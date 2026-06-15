part of 'theme.dart';

class ThemeSpacing extends Equatable {
  const ThemeSpacing({this.md = 15, this.lg = 20, this.sm = 8});

  final double sm;
  final double md;
  final double lg;

  @override
  List<Object?> get props => [sm, md, lg];
}
