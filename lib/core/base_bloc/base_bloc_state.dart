part of 'base_bloc.dart';

class CustomState extends Equatable {
  final String message;
  final String title;

  const CustomState({required this.message, required this.title});

  @override
  List<Object?> get props => [message, title];
}

abstract class BaseBlocState extends Equatable {
  final CustomState? error;
  final bool loading;

  const BaseBlocState({required this.error, required this.loading});
  BaseBlocState copyWith({CustomState? error, bool? loading});

  @override
  List<Object?> get props => [error, loading];
}
