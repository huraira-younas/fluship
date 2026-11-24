part of 'base_bloc.dart';

class const CustomState({
  required final String message,
  required final String title,
}) extends Equatable {
  @override
  List<Object?> get props => [message, title];
}

abstract class const BaseBlocState({
  required final CustomState? error,
  required final bool loading,
}) extends Equatable {
  BaseBlocState copyWith({CustomState? error, bool? loading});

  @override
  List<Object?> get props => [error, loading];
}
